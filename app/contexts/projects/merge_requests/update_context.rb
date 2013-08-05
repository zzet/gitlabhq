module Projects
  # Build collection of Merge Requests
  # based on filtering passed via params for @project
  module MergeRequests
    class UpdateContext < Projects::MergeRequests::BaseContext
      def execute
        if @merge_request.update_attributes(params[:merge_request].merge(author_id_of_changes: @current_user.id))
          @merge_request.reload_code
          @merge_request.mark_as_unchecked

          receive_delayed_notifications

          return true
        end

        return false
      end
    end
  end
end
