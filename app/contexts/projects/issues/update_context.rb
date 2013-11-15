module Projects
  # Build collection of Merge Requests
  # based on filtering passed via params for @project
  module Issues
    class UpdateContext < Projects::Issues::BaseContext
      def execute
        if issue.update_attributes(params)
          receive_delayed_notifications
          return true
        end

        return false
      end
    end
  end
end
