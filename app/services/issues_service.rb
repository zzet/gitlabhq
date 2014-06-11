class IssuesService < BaseService

  attr_accessor :current_user, :project, :issue, :params

  def initialize(user, issue, params = {}, project = nil)
    @current_user, @project, @issue, @params = user, project, issue, params.dup
  end

  def create
    @issue = Issue.new(params[:issue])
    @issue.author = @current_user
    binding.pry
    if params[:project_id].blank?
      @issue.project = project
    else
      @issue.project = Project.find_with_namespace(params[:project_id])
    end

    if @issue.save
      receive_delayed_notifications
    end

    @issue
  end

  def close(commit = nil)
    if @issue.close
      Note.create_status_change_note(@issue, @issue.project, current_user, @issue.state, commit)
      execute_hooks(@issue)
    end

    @issue
  end

  def update
    if @issue.update_attributes(params[:issue])
      receive_delayed_notifications
    end

    @issue
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

  private

  def execute_hooks(issue)
    project.execute_hooks(issue.to_hook_data, :issue_hooks)
  end
end
