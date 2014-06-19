class DashboardController < ApplicationController
  respond_to :html

  before_filter :load_projects, except: [:projects]
  before_filter :event_filter, only: :show
  before_filter :default_filter, only: [:issues, :merge_requests]


  def show
    # Fetch only 30 projects.
    # If user needs more - point to Dashboard#projects page
    @projects_limit = 30

    @groups = current_user.personal_groups.sort_by(&:human_name)
    @has_authorized_projects = @projects.count > 0
    @teams = current_user.teams
    @projects_count = @projects.count
    @projects = @projects.limit(@projects_limit).includes(:namespace)

    @events = Event.for_main_dashboard(current_user)
    @events = @event_filter.apply_filter(@events)
    @events = @events.limit(20).offset(params[:offset] || 0).recent

    @last_push = current_user.recent_push

    @publicish_project_count = Project.publicish(current_user).count

    respond_to do |format|
      format.html
      format.json { pager_json("events/_events", @events.count) }
      format.atom do
        @events = old_events
        render layout: false
      end
    end
  end

  def teams
    @teams = case params[:scope]
                when 'personal' then
                  current_user.personal_teams
                when 'joined' then
                  current_user.teams
                when 'owned' then
                  current_user.owned_teams
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

    @projects = @projects.where(namespace_id: Group.find_by(name: params[:group])) if params[:group].present?
    @projects = @projects.where(id: Team.find_by(name: params[:team]).projects) if params[:team].present?
    @projects = @projects.where(visibility_level: params[:visibility_level]) if params[:visibility_level].present?
    @projects = @projects.tagged_with(params[:label]) if params[:label].present?
    @projects = @projects.page(params[:page]).per(30)
    @projects = @projects.includes(:namespace)
    #@projects = @projects.includes(:namespace).sorted_by_activity
    @sort = params[:sort]
    @projects = @projects.sort(@sort)


    @labels = current_user.authorized_projects.tags_on(:labels)
    @groups = current_user.groups
    @teams = current_user.teams
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

  protected

  def load_projects
    @projects = current_user.authorized_projects.sorted_by_push_date.non_archived
    @authorized_projects = @projects.count < 20 ? current_user.authorized_projects.where.not(id: @projects).sorted_by_push_date.non_archived.limit(10) : []
  end

  def default_filter
    params[:scope] = 'assigned-to-me' if params[:scope].blank?
    params[:state] = 'opened' if params[:state].blank?
    params[:authorized_only] = true
  end

  def old_events
    @old_events ||= begin
      events = OldEvent.in_projects(current_user.authorized_projects.pluck(:id))
      events.limit(20).offset(params[:offset] || 0)
    end
  end
end
