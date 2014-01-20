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
    team.destroy
    receive_delayed_notifications
  end
end
