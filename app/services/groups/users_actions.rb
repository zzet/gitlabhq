module Groups::UsersActions
  private

  def add_user_membership_action
    user_ids = if params[:user_ids].respond_to?(:each)
                 params[:user_ids]
               else
                 params[:user_ids].split(',')
               end

    multiple_action("memberships_add", "group", group, user_ids) do
      group.add_users(user_ids, params[:group_access])
    end

    Elastic::BaseIndexer.perform_async(:update, group.class.name, group.id)

    group.projects.find_each do |project|
      Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
    end
  end

  def remove_user_membership_action(member)
    gur = group_member_relation(member)

    if gur.user != group.owner
      gur.destroy
      receive_delayed_notifications

      Elastic::BaseIndexer.perform_async(:update, group.class.name, group.id)

      group.projects.find_each do |project|
        Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
      end
    end

  end

  def update_user_membership_action(member)
    gur = group_member_relation(member)
    gur.update(params)

    if gur.valid?
      receive_delayed_notifications

      Elastic::BaseIndexer.perform_async(:update, group.class.name, group.id)

      group.projects.find_each do |project|
        Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
      end

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
