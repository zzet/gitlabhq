module Projects
  # Build collection of Merge Requests
  # based on filtering passed via params for @project
  module MergeRequests
    class CreateContext < Projects::BaseContext
      def execute
        @merge_request = MergeRequest.new(params)
        @merge_request.target_project = project if @merge_request.target_project.blank?
        @merge_request.source_project = project if @merge_request.source_project.blank?
        @merge_request.author = @current_user

        if @merge_request.save
          @merge_request.reload_code

          receive_delayed_notifications
        end

        @merge_request
      end
    end
  end
end
