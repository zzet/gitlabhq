module Groups::UsersActions
  private

  def add_user_membership_action
    user_ids = if params[:user_ids].respond_to?(:each)
                 params[:user_ids]
               else
                 params[:user_ids].split(',')
               end

    if user_ids.many?
      RequestStore.store[:borders] ||= []
      RequestStore.store[:borders].push("gitlab.memberships_add.project")
      Gitlab::Event::Action.trigger :memberships_add, group
    end

    group.add_users(user_ids, params[:group_access])

    RequestStore.store[:borders].pop if user_ids.many?

    receive_delayed_notifications
  end

  def remove_user_membership_action(member)
    gur = group_member_relation(member)

    if gur.user != group.owner
      gur.destroy
      receive_delayed_notifications
    end
  end

  def update_user_membership_action(member)
    gur = group_member_relation(member)
    gur.update(params)

    if gur.valid?
      receive_delayed_notifications
      return true
    else
      return false
    end
  end

  private

  def group_member_relation(member)
    member.users_groups.find_by(group_id: group)
  end
end
