module Projects
  # Build collection of Merge Requests
  # based on filtering passed via params for @project
  module MergeRequests
    class CreateContext < Projects::BaseContext
      def execute
        @merge_request = @project.merge_requests.new(params[:merge_request])
        @merge_request.author = @current_user

        if @merge_request.save
          @merge_request.reload_code

          receive_delayed_notifications

          return true
        end

        return false
      end
    end
  end
end
