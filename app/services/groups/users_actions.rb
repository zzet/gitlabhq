module Groups::UsersActions
  private

  def add_user_membership_action
    user_ids = if params[:user_ids].respond_to?(:each)
                 params[:user_ids]
               else
                 params[:user_ids].split(',')
               end

    action = Gitlab::Event::SyntheticActions::MEMBERSHIPS_ADD
    multiple_action(action, "group", group, user_ids) do
      group.add_users(user_ids, params[:group_access])
    end

    update_group_projects_indexes(group)
  end

  def remove_user_membership_action(member)
    gur = group_member_relation(member)

    if gur.user != group.owner
      gur.destroy
      receive_delayed_notifications

      update_group_projects_indexes(group)
    end

  end

  def update_user_membership_action(member)
    gur = group_member_relation(member)
    gur.update(params)

    if gur.valid?
      receive_delayed_notifications

      update_group_projects_indexes(group)

      return true
    else
      return false
    end
  end

  private

  def group_member_relation(member)
    member.users_groups.find_by(group_id: group)
  end

  def update_group_projects_indexes(group)
    group.projects.pluck(:id).each do |project_id|
      reindex_with_elastic(Project, project_id)
    end
  end
end
