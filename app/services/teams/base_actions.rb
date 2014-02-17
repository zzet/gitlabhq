module Teams::BaseActions
  private

  def create_action
    @team = Team.new(params)
    @team.creator = current_user unless params[:creator]
    @team.public = true
    @team.path = @team.name.dup.parameterize if @team.name
    @team.save

    receive_delayed_notifications

    @team
  end

  def remove_action
    project_ids = (team.projects.ids + team.accessed_projects).uniq
    group_ids   = team.groups.ids
    user_ids = team.users.ids

    team.destroy

    User.where(id: user_ids).find_each do |member|
      Elastic::BaseIndexer.perform_async(:update, member.class.name, member.id)
    end

    Project.where(id: project_ids).find_each do |project|
      Elastic::BaseIndexer.perform_async(:update, project.class.name, project.id)
    end

    Group.where(id: group_ids).find_each do |group|
      Elastic::BaseIndexer.perform_async(:update, group.class.name, group.id)
    end

    receive_delayed_notifications
  end
end
