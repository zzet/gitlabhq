class Admin::Projects::MembersController < Admin::Projects::ApplicationController
  def edit
    @member = team_member
    @project = project
    @team_member_relation = team_member_relation
  end

  def update
    if ProjectsService.new(@current_user, @project, params).update_membership(team_member)
      redirect_to [:admin, project],  notice: 'Project Access was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    ProjectsService.new(@current_user, @project, params).remove_membership(team_member)

    redirect_to :back
  end

  private

  def team_member
    @member ||= project.users.find_by_username(params[:id])
  end
end
