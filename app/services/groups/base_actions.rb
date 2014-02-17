module Groups::BaseActions
  private

  def create_action
    group = Group.new(params)
    group.path = group.name.dup.parameterize  if group.name && params[:path].blank?
    group.owner = current_user                if params[:owner_id].blank?

    if group.save
      group.add_owner(current_user)
    end

    receive_delayed_notifications

    group
  end

  def delete_action
    team_ids = group.teams.ids

    group.destroy

    Team.where(id: team_ids).find_each do |team|
      Elastic::BaseIndexer.perform_async(:update, team.class.name, team.id)
    end

    receive_delayed_notifications
  end
end
