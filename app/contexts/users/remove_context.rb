module Users
  class RemoveContext < Users::BaseContext
    def execute
      user.destroy

      receive_delayed_notifications
    end
  end
end
