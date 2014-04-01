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
    team_ids = group.teams.select("teams.id")

    group.destroy

    team_ids.each do |team_id|
      reindex_with_elastic(Team, team_id)
    end

    receive_delayed_notifications
  end
end
