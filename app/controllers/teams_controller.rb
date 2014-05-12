class TeamsController < ApplicationController
  # Authorize

  before_filter :authorize_create_team!, only: [:new, :create]
  before_filter :authorize_manage_team!, only: [:edit, :update]
  before_filter :authorize_remove_team!, only: [:destroy]

  before_filter :team, except: [:index, :new, :create]
  before_filter :event_filter, only: :show

  layout :determine_layout

  before_filter :set_title, only: [:new, :create]

  def index
    redirect_to teams_dashboard_path
  end

  def show
    projects
    groups
    members
    @events = Event.for_dashboard(@team)
    @events = event_filter.apply_filter(@events) if (@event_filter.params - %w(group)).any?
    @events = @events.limit(20).offset(params[:offset] || 0).recent

    respond_to do |format|
      format.html
      format.js
      format.json { pager_json("events/_events", @events.count) }
      format.atom { render layout: false }
    end
  end

  def edit
    render 'edit', layout: "team_settings"
  end

  def update
    if team.update_attributes(params[:team])
      redirect_to edit_team_path(team)
    else
      render action: :edit
    end
  end

  def destroy
    ::TeamsService.new(current_user, team).delete

    redirect_to dashboard_path
  end

  def new
    @team = Team.new
  end

  def create
    @team = ::TeamsService.new(current_user, params[:team]).create
    if @team.persisted?
      redirect_to team_path(@team)
    else
      render action: :new
    end
  end

  protected

  def projects
    @projects ||= team.projects.sorted_by_push_date
  end

  def groups
    @groups ||= team.groups
  end

  def members
    @members ||= team.members
  end

  def teams
    @teams ||= current_user.authorized_teams
  end

  def team
    @team ||= teams.find_by_path(params[:id])
    raise ActiveRecord::RecordNotFound if @team.nil?
    @team
  end

  # Dont allow unauthorized access to team
  def authorize_read_team!
    unless teams.present? or can?(current_user, :read_team, team)
      return render_404
    end
  end

  def authorize_create_team!
    unless can?(current_user, :create_team, nil)
      return render_404
    end
  end

  def authorize_manage_team!
    unless can?(current_user, :manage_team, team)
      return render_404
    end
  end

  def authorize_remove_team!
    unless can?(current_user, :remove_team, team)
      return render_404
    end
  end

  def set_title
    @title = 'New Team'
  end

  def determine_layout
    if [:index, :new, :create].include?(action_name.to_sym)
      'navless'
    else
      'team'
    end
  end
end
