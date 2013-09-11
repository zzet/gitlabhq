module Teams
  class CreateContext < BaseContext
    def execute
      @team = Team.new(params[:team])
      @team.creator = current_user unless params[:creator]
      @team.path = @team.name.dup.parameterize if @team.name
      @team.save

      receive_delayed_notifications

      @team
    end
  end
end
