module Teams
  class RemoveContext < Teams::BaseContext
    def execute
      team.destroy

      receive_delayed_notifications
    end
  end
end
