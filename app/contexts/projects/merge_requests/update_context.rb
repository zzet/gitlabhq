module Projects
  # Build collection of Merge Requests
  # based on filtering passed via params for @project
  module MergeRequests
    class UpdateContext < Projects::MergeRequests::BaseContext
      def execute
        # We dont allow change of source/target projects
        # after merge request was created
        params[:merge_request].delete(:source_project_id)
        params[:merge_request].delete(:target_project_id)

        if @merge_request.update_attributes(@params[:merge_request].merge(author_id_of_changes: @current_user.id))
          @merge_request.reload_code
          @merge_request.mark_as_unchecked
          @merge_request.reset_events_cache

          receive_delayed_notifications

          return true
        end

        return false
      end
    end
  end
end
