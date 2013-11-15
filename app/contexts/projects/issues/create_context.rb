module Projects
  # Build collection of Merge Requests
  # based on filtering passed via params for @project
  module Issues
    class CreateContext < Projects::BaseContext
      def execute
        @issue = Issue.new(params)
        @issue.author = @current_user

        if @issue.save
          receive_delayed_notifications
        end

        @issue
      end
    end
  end
end
