module Projects
  module Issues
    class BulkUpdateContext < Projects::BaseContext
      def execute
        update_data = params[:update]

        issues_ids   = update_data[:issues_ids].split(",")
        milestone_id = update_data[:milestone_id]
        assignee_id  = update_data[:assignee_id]
        status       = update_data[:status]

        opts = {}
        opts[:milestone_id] = milestone_id if milestone_id.present?
        opts[:assignee_id] = assignee_id if assignee_id.present?

        if status.present?
          if status == 'closed'
            opts[:state_event] = "close"
          else
            opts[:state_event] = "reopen"
          end
        end

        issues = Issue.where(id: issues_ids).all
        issues = issues.select { |issue| can?(current_user, :modify_issue, issue) }

        issues.each do |issue|
          Projects::Issues::UpdateContext.new(current_user, issue.project, issue, opts).execute
        end

        {
          count: issues.count,
          success: !issues.count.zero?
        }
      end
    end
  end
end
