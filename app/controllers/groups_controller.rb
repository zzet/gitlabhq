class GroupsController < ApplicationController
  respond_to :html
  before_filter :group, except: [:new, :create]

  # Authorize
  before_filter :authorize_read_group!, except: [:new, :create, :index]
  before_filter :authorize_admin_group!, only: [:edit, :update, :destroy]
  before_filter :authorize_create_group!, only: [:new, :create]

  # Load group projects
  before_filter :projects, except: [:new, :create, :index]

  def index
    @groups = current_user.authorized_groups
    @groups = @groups.search(params[:name]) if params[:name].present?
  end

  before_filter :default_filter, only: [:issues, :merge_requests]

  layout :determine_layout

  before_filter :set_title, only: [:new, :create]

  def new
    @group = Group.new
  end

  def create
    @group = GroupsService.new(current_user, params[:group]).create
    if @group.persisted?
      redirect_to @group, notice: 'Group was successfully created.'
    else
      render action: "new"
    end
  end

  def show
    @events = OldEvent.in_projects(project_ids)
    @events = event_filter.apply_filter(@events)
    @events = @events.limit(20).offset(params[:offset] || 0)
    @last_push = current_user.recent_push

    @teams = @group.teams
    @projects = @group.projects.sorted_by_push_date

    @owners = @group.owners
    @masters = @group.masters
    @developers = @group.developers
    @reporters = @group.reporters
    @guests = @group.guests

    @teams.each do |team|
      @owners += team.owners
      @masters += team.masters
      @developers += team.developers
      @reporters += team.reporters
      @guests += team.guests
    end

    @owners = @owners.uniq
    @masters = (@masters - @owners).uniq
    @developers = (@developers - (@owners + @masters)).uniq
    @reporters = (@reporters - (@owners + @masters + @developers)).uniq
    @guests = (@guests - (@owners + @masters + @developers + @reporters)).uniq

    @members_count = @owners.count + @masters.count + @developers.count + @reporters.count + @guests.count

    respond_to do |format|
      format.html
      format.json { pager_json("events/_events", @events.count) }
      format.atom { render layout: false }
    end
  end

  def merge_requests
    @merge_requests = FilteringService.new.execute(current_user, MergeRequest, params)
    @merge_requests = @merge_requests.of_group(@group)
    @merge_requests = @merge_requests.recent.page(params[:page]).per(20)
  end

  def issues
    @issues = FilteringService.new.execute(current_user, Issue, params)
    @issues = @issues.of_group(@group)
    @issues = @issues.recent.page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def members
    @project = group.projects.find(params[:project_id]) if params[:project_id]
    @members = group.users_groups.order('group_access DESC')
    @users_group = UsersGroup.new
  end

  def edit
    render :edit, layout: 'group_settings'
  end

  def update
    if @group.update_attributes(params[:group])
      redirect_to @group, notice: 'Group was successfully updated.'
    else
      render action: :edit, layout: 'group_settings'
    end
  end

  def destroy
    ::GroupsService.new(current_user, group).delete

    redirect_to root_path, notice: 'Group was removed.'
  end

  protected

  def group
    @group ||= Group.find_by(path: params[:id])
  end

  def projects
    @projects ||= (current_user.admin? ? Project.all : current_user.known_projects).where(namespace_id: group.id).sorted_by_push_date
  end

  def project_ids
    projects.map(&:id)
  end

  # Dont allow unauthorized access to group
  def authorize_read_group!
    unless @group and (projects.present? or can?(current_user, :read_group, @group))
      return render_404
    end
  end

  def authorize_create_group!
    unless can?(current_user, :create_group, nil)
      return render_404
    end
  end

  def authorize_admin_group!
    unless can?(current_user, :manage_group, group)
      return render_404
    end
  end

  def set_title
    @title = 'New Group'
  end

  def determine_layout
    if [:new, :create].include?(action_name.to_sym)
      'navless'
    else
      'group'
    end
  end

  def default_filter
    params[:scope] = 'assigned-to-me' if params[:scope].blank?
    params[:state] = 'opened' if params[:state].blank?
    params[:group_id] = @group.id
  end
end
