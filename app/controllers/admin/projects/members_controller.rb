class Admin::Projects::MembersController < Admin::Projects::ApplicationController
  def edit
    @member = team_member
    @project = project
    @team_member_relation = team_member_relation
  end

  def update
    if Projects::Users::UpdateRelationContext.new(@current_user, @project, team_member, params).execute
      redirect_to [:admin, project],  notice: 'Project Access was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    Projects::Users::RemoveRelationContext.new(@current_user, @project, member, params).execute

    redirect_to :back
  end

  private

  def team_member
    @member ||= project.users.find_by_username(params[:id])
  end
end
