class GroupsController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show, :issues, :members, :merge_requests]
  respond_to :html
  before_filter :group, except: [:new, :create]

  # Authorize
  before_filter :authorize_read_group!, except: [:new, :create]
  before_filter :authorize_admin_group!,  only: [:edit, :update, :destroy, :projects]
  before_filter :authorize_create_group!, only: [:new, :create]
  before_filter :event_filter, only: :show

  # Load group projects
  before_filter :load_projects, except: [:new, :create, :projects, :edit, :update]

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
    @dashboard = @group.class
    @events = Event.for_dashboard(@group)
    @events = @event_filter.apply_filter(@events) if (@event_filter.params - %w(team)).any?
    @events = @events.limit(20).offset(params[:offset] || 0).recent

    @last_push = current_user.recent_push if current_user.present?

    @teams = @group.teams
    @projects = @projects.sorted_by_push_date

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
      format.atom do
        @events = old_events
        render layout: false
      end
    end
  end

  def merge_requests
    @merge_requests = MergeRequestsFinder.new.execute(current_user, params)
    @merge_requests = @merge_requests.page(params[:page]).per(20)
    @merge_requests = @merge_requests.preload(:author, :target_project)
  end

  def issues
    @issues = IssuesFinder.new.execute(current_user, params)
    @issues = @issues.page(params[:page]).per(20)
    @issues = @issues.preload(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def members
    @project = group.projects.find(params[:project_id]) if params[:project_id]
    @members = group.users_groups

    if params[:search].present?
      users = group.users.search(params[:search]).records
      @members = @members.where(user_id: users)
    end

    @members = @members.order('group_access DESC').page(params[:page]).per(50)
    @users_group = UsersGroup.new
  end

  def edit
    render :edit, layout: 'group_settings'
  end

  def projects
    @projects = @group.projects.page(params[:page])
  end

  def update
    if @group.update_attributes(params[:group])
      redirect_to edit_group_path(@group), notice: 'Group was successfully updated.'
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

  def load_projects
    @projects ||= ProjectsFinder.new.execute(current_user, group: group).sorted_by_push_date.non_archived
  end

  def project_ids
    @projects.pluck(:id)
  end

  # Dont allow unauthorized access to group
  def authorize_read_group!
    unless @group and (@projects.present? or can?(current_user, :read_group, @group))
      if current_user.nil?
        return authenticate_user!
      else
        return render_404
      end
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
    elsif current_user
      'group'
    else
      'public_group'
    end
  end

  def default_filter
    if params[:scope].blank?
      if current_user
        params[:scope] = 'assigned-to-me'
      else
        params[:scope] = 'all'
      end
    end
    params[:state] = 'opened' if params[:state].blank?
    params[:group_id] = @group.id
  end

  def old_events
    @old_events ||= begin
      events = OldEvent.in_projects(project_ids)
      events.limit(20).offset(params[:offset] || 0)
    end
  end

end
