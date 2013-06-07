module Projects
  class RemoveContext < Projects::BaseContext
    def execute
      project.destroy

      receive_delayed_notifications
    end
  end
end
