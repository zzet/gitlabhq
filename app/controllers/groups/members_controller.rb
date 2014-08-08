class Groups::MembersController < Groups::ApplicationController

  before_filter :authorize_admin_group!, only: [:index, :create, :update, :destroy]

  def index
    @members = group.users_groups.order(group_access: :desc)
    @member_group_relation = group.users_groups.build
    #@avaliable_members = User.not_in_group(@group)
    render :index, layout: 'group_settings'
  end

  def create
    ::GroupsService.new(@current_user, group, params).add_membership

    redirect_to group_members_path(@group), notice: 'Users were successfully added.'
  end

  def update
    ::GroupsService.new(@current_user, group, params[:group_member]).update_membership(member)
    redirect_to group_members_path(group), notice: "Member was successfully updated."
  end

  def destroy
    ::GroupsService.new(@current_user, group).remove_membership(member)

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
