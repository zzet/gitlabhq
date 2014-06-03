class MergeRequestsService < BaseService
  attr_accessor :current_user, :merge_request, :params,
    :source_project, :target_project

  def initialize(user, merge_request, params = {}, source_project = nil, target_project = nil)
    @current_user = user
    @merge_request = merge_request
    @params = params.dup
    @source_project = source_project || @merge_request.source_project
    @target_project = target_project || @merge_request.target_project
  end

  def create
    @merge_request = MergeRequest.new(params)
    @merge_request.target_project = target_project if @merge_request.target_project.blank?
    @merge_request.source_project = source_project if @merge_request.source_project.blank?
    @merge_request.author = @current_user

    if @merge_request.save
      #@merge_request.reload_code
      @merge_request.create_cross_references!(@merge_request.project, @current_user)
      execute_hooks(merge_request)
      receive_delayed_notifications
    end

    if @merge_request.target_project && @merge_request.target_project.jenkins_ci_with_mr?
      type = if @merge_request.target_project == @merge_request.source_project
               :project
             else
               :fork
             end
      service = @merge_request.target_project.jenkins_ci
      service.build_merge_request(merge_request, current_user, type)
    end

    @merge_request
  end

  def close(commit = nil)
    merge_request.allow_broken = true

    if merge_request.close
      create_note(merge_request)
      execute_hooks(merge_request)
    end

    merge_request
  end

    def reopen
      if merge_request.reopen
        create_note(merge_request)
        execute_hooks(merge_request)
        merge_request.reload_code
        merge_request.mark_as_unchecked
      end

      merge_request
    end

  def update
    # If we close MergeRequest we want to ignore validation
    # so we can close broken one (Ex. fork project removed)
    state = params.delete('state_event')
    case state
    when 'reopen'
      reopen
    when 'close'
      close
    end

    # We dont allow change of source/target projects
    # after merge request was created
    params[:merge_request].delete(:source_project_id)
    params[:merge_request].delete(:target_project_id)

    if params[:merge_request].any? &&
      @merge_request.update_attributes(@params[:merge_request])

      @merge_request.reset_events_cache

      if @merge_request.previous_changes.include?('assignee_id')
        create_assignee_note(@merge_request)
      end

      @merge_request.notice_added_references(@merge_request.project, current_user)

      execute_hooks(@merge_request)

      @merge_request.reload

      receive_delayed_notifications
    end

    @merge_request
  end

  # Mark existing merge request as merged
  # and execute all hooks and notifications
  # Called when you do merge via command line and push code
  # to target branch
  def merge
    merge_request.merge

    create_merge_event(merge_request)
    execute_hooks(merge_request)

    receive_delayed_notifications

    true
  rescue
    false
  end

  # Do git merge in satellite and in case of success
  # mark merge request as merged and execute all hooks and notifications
  # Called when you do merge via GitLab UI
  def auto_merge(commit_message)
    merge_request.lock

    if Gitlab::Satellite::MergeAction.new(current_user,
                                          merge_request).merge!(commit_message)
      merge_request.merge

      create_merge_event(merge_request)
      execute_hooks(merge_request)

      receive_delayed_notifications

      true
    else
      merge_request.unlock
      false
    end
  rescue
    merge_request.unlock if merge_request.locked?
    merge_request.mark_as_unmergeable
    false
  end

  private

  def create_merge_event(merge_request)
    OldEvent.create(
      project: merge_request.target_project,
      target_id: merge_request.id,
      target_type: merge_request.class.name,
      action: OldEvent::MERGED,
      author_id: current_user.id
    )
  end

  def create_assignee_note(merge_request)
    Note.create_assignee_change_note(merge_request,
                                     merge_request.project,
                                     current_user,
                                     merge_request.assignee)
  end

  def create_note(merge_request)
    Note.create_status_change_note(merge_request,
                                   merge_request.target_project,
                                   current_user,
                                   merge_request.state,
                                   nil)
  end

  def execute_hooks(merge_request)
    if merge_request.project
      merge_request.project.execute_hooks(merge_request.to_hook_data,
                                          :merge_request_hooks)
    end
  end
end
