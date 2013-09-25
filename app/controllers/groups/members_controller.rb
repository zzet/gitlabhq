class Groups::MembersController < Groups::ApplicationController

  before_filter :authorize_admin_group!, only: [:new, :edit, :create, :update, :destroy]

  def index
    @members = group.users_groups.order("group_access DESC")
    @member_group_relation = group.users_groups.build
    @avaliable_members = User.not_in_group(@group)
    render :index, layout: 'group_settings'
  end

  def create
    ::Groups::Users::CreateRelationContext.new(@current_user, group, params).execute

    redirect_to group_members_path(@group), notice: 'Users were successfully added.'
  end

  def update
    ::Groups::Users::UpdateRelationContext.new(@current_user, group, member, params[:group_member]).execute
    redirect_to group_members_path(group), notice: "Member was successfully updated."
  end

  def destroy
    ::Groups::Users::RemoveRelationContext.new(@current_user, group, member).execute

    respond_to do |format|
      format.html { redirect_to group_members_path(@group), notice: 'User was successfully removed from group.' }
      format.js { render nothing: true }
    end
  end

  protected

  def member
    @member ||= (params[:id].present? ? User.find_by_username(params[:id]) : User.find(params[:user_id]))
  end
end
