class Projects::TeamMembersController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!, except: :leave

  layout "project_settings"

  def index
    @group = @project.group
    @users_projects = @project.users_projects.order('project_access DESC')
    teams_ids = @project.teams.pluck(:id)
    teams_ids += @group.teams.pluck(:id) if @group.present?
    @teams = Team.where(id: teams_ids)

    #NOTE This part of code has to combine members of project, group and teams and their access levels,
    #     and then sort access levels. Next two variables used in views in all_members parts.
    #TODO Need refactoring
    @all_members = []
    @accesses = {}

    @users_projects.each do |member|
      user = member.user
      @all_members << user
      @accesses[user.id] ||= []
      @accesses[user.id] << {
        from: @project,
        human_access: member.human_access,
        access: member.access_field
      }
    end

    if @group.present?
      @group.users_groups.each do |member|
        user = member.user
        @all_members << user
        @accesses[user.id] ||= []
        @accesses[user.id] << {
          from: @group,
          human_access: member.human_access,
          access: member.access_field
        }
      end
    end

    @teams.each do |team|
      team.team_user_relationships.each do |member|
        user = member.user
        @all_members <<  user
        @accesses[user.id] ||= []
        @accesses[user.id] << {
          from: team,
          human_access: member.human_access,
          access: member.access_field
        }
      end
    end

    ar = @accesses.map do |user_id, accesses|
      [
        user_id,
        accesses.sort { |a, b| b[:access] <=> a[:access] }
      ]
    end
    @accesses = Hash[ar]

    @all_members.uniq!
    @all_members.sort! do |a, b|
      a_access = @accesses[a.id].first[:access]
      b_access = @accesses[b.id].first[:access]

      b_access <=> a_access
    end
  end

  def new
    @user_project_relation = project.users_projects.new
  end

  def create
    Projects::Users::CreateRelationContext.new(@current_user, @project, params).execute

    if params[:redirect_to]
      redirect_to params[:redirect_to]
    else
      redirect_to project_team_index_path(@project)
    end
  end

  def update
    unless Projects::Users::UpdateRelationContext.new(@current_user, @project, member, params).execute
      flash[:alert] = "User should have at least one role"
    end

    redirect_to project_team_index_path(@project)
  end

  def destroy
    Projects::Users::RemoveRelationContext.new(@current_user, @project, member, params).execute

    respond_to do |format|
      format.html { redirect_to project_team_index_path(@project) }
      format.js { render nothing: true }
    end
  end

  def leave
    project.users_projects.find_by_user_id(current_user).destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render nothing: true }
    end
  end

  def apply_import
    status = Projects::Users::ImportRelationContext.new(@current_user, @project, params).execute
    notice = status ? "Succesfully imported" : "Import failed"

    redirect_to project_team_index_path(project), notice: notice
  end

  protected

  def member
    @member ||= User.find_by_username(params[:id])
  end
end
