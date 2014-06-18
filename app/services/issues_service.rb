class IssuesService < BaseService

  attr_accessor :current_user, :project, :issue, :params

  def initialize(user, issue, params = {}, project = nil)
    @current_user, @project, @issue = user, project, issue
    @params = params[:issue].present? ? params.dup : { issue: params.dup }
  end

  def create
    @issue = Issue.new(params[:issue])
    @issue.author = @current_user
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

  def reopen
    if @issue.reopen
      Note.create_status_change_note(@issue, @issue.project, current_user, @issue.state, commit)
      execute_hooks(@issue)
    end

    @issue
  end

  def close(commit = nil)
    if @issue.close
      Note.create_status_change_note(@issue, @issue.project, current_user, @issue.state, commit)
      @issue.create_cross_references!(@issue.project, current_user)
      execute_hooks(@issue)
    end

    @issue
  end

  def update
    state = params.delete('state_event') || params.delete(:state_event)

    case state
    when 'reopen'
      @issue = reopen
    when 'close'
      @issue = close
    end

    if params[:issue].any?
      if @issue.update(params[:issue])
        @issue.reset_events_cache

        @issue.notice_added_references(@issue.project, current_user)

        if @issue.previous_changes.include?('assignee_id')
          Note.create_assignee_change_note(@issue,
                                           @issue.project,
                                           current_user,
                                           @issue.assignee)
        end

        execute_hooks(@issue)

        receive_delayed_notifications
      end
    end

    @issue
  end

  def bulk_update
    update_data  = params[:issue][:update]

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
