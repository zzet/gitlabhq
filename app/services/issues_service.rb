class IssuesService < BaseService

  attr_accessor :current_user, :project, :issue, :params

  def initialize(user, issue, params = {}, project = nil)
    @current_user, @project, @issue, @params = user, project, issue, params.dup
  end

  def create
    @issue = Issue.new(params)
    @issue.author = @current_user
    @issue.project = project if params[:project_id].blank? && project.present?

    if @issue.save
      receive_delayed_notifications
    end

    @issue
  end

  def update
    if issue.update(params)
      receive_delayed_notifications
      return true
    end

    return false
  end

  def bulk_update
    update_data  = params[:update]

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

    issues = Issue.where(id: issues_ids)
    issues = issues.select { |issue| can?(current_user, :modify_issue, issue) }

    issues.each do |issue|
      ProjectsService.new(current_user, issue.project, opts).issue(issue).update
    end

    {
      count: issues.count,
      success: !issues.count.zero?
    }
  end
end
