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
    project_ids = (team.projects.pluck(:id) + team.accessed_projects.pluck(:id)).uniq

    team.destroy

    project_ids.each do |project_id|
      reindex_with_elastic(Project, project_id)
    end

    receive_delayed_notifications
  end
end
