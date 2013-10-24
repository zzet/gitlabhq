class DashboardController < ApplicationController
  respond_to :html

  before_filter :load_projects, except: [:projects]
  before_filter :event_filter, only: :show

  def show
    @groups = current_user.personal_groups.sort_by(&:human_name)
    @has_authorized_projects = @projects.count > 0
    @teams = current_user.teams
    @projects_count = @projects.count
    @projects = @projects.limit(20)

    @events = OldEvent.in_projects(current_user.authorized_projects.pluck(:id))
    @events = @event_filter.apply_filter(@events)
    @events = @events.limit(20).offset(params[:offset] || 0)

    @last_push = current_user.recent_push

    respond_to do |format|
      format.html
      format.js
      format.atom { render layout: false }
    end
  end

  def projects
    @projects = case params[:scope]
                when 'personal' then
                  current_user.namespace.projects
                when 'joined' then
                  current_user.authorized_projects.joined(current_user)
                when 'owned' then
                  current_user.owned_projects
                else
                  current_user.authorized_projects
                end.sorted_by_push_date

    @projects = @projects.where(namespace_id: Group.find_by_name(params[:group])) if params[:group].present?
    @projects = @projects.where(id: Team.find_by_name(params[:team]).projects) if params[:team].present?
    @projects = @projects.includes(:namespace).sorted_by_activity

    @labels = current_user.authorized_projects.tags_on(:labels)
    @groups = current_user.groups
    @teams = current_user.teams

    @projects = @projects.tagged_with(params[:label]) if params[:label].present?
    @projects = @projects.page(params[:page]).per(30)
  end

  def teams
    @teams = case params[:scope]
                when 'personal' then
                  current_user.personal_teams
                when 'joined' then
                  current_user.teams
                when 'owned' then
                  current_user.own_teams
                else
                  current_user.authorized_teams
                end

    @teams = @teams.with_group(Group.find_by_name(params[:group])) if params[:group].present?
    @teams = @teams.with_project(Project.find_with_namespace(params[:project])) if params[:project].present?

    @groups = current_user.authorized_groups
    @projects = current_user.authorized_projects

    #@labels = current_user.authorized_teams.tags_on(:labels)
    #@teams = @teams.tagged_with(params[:label]) if params[:label].present?
    @teams = @teams.page(params[:page]).per(30)
  end


  # Get authored or assigned open merge requests
  def merge_requests
    @merge_requests = current_user.cared_merge_requests
    @merge_requests = FilterContext.new(@current_user, @merge_requests, params).execute
    @merge_requests = @merge_requests.recent.page(params[:page]).per(20)
  end

  # Get only assigned issues
  def issues
    @issues = current_user.assigned_issues
    @issues = FilterContext.new(@current_user, @issues, params).execute
    @issues = @issues.recent.page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  protected

  def load_projects
    @projects = current_user.authorized_projects.sorted_by_push_date
    @authorized_projects = @projects.count < 20 ? current_user.authorized_projects.where("projects.id not in (?)", @projects.pluck(:id)).sorted_by_push_date.limit(10) : []
  end
end
