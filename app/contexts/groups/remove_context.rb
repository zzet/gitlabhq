module Groups
  class RemoveContext < Groups::BaseContext
    def execute
      group.truncate_teams
      group.destroy

      receive_delayed_notifications
    end
  end
end
