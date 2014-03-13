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
      @merge_request.reload_code
      receive_delayed_notifications
    end

    if @merge_request.target_project && @merge_request.target_project.jenkins_ci_with_mr?
      type = (@merge_request.target_project == @merge_request.source_project ? :project : :fork)
      service = @merge_request.target_project.jenkins_ci
      service.build_merge_request(merge_request, current_user, type)
    end

    @merge_request
  end

  def update
    # If we close MergeRequest we want to ignore validation
    # so we can close broken one (Ex. fork project removed)
    if params[:merge_request] == {"state_event"=>"close"}
      @merge_request.allow_broken = true
      result = @merge_request.close
      receive_delayed_notifications if result
      return result
    end

    # We dont allow change of source/target projects
    # after merge request was created
    params[:merge_request].delete(:source_project_id)
    params[:merge_request].delete(:target_project_id)

    if @merge_request.update(@params[:merge_request].merge(author_id_of_changes: @current_user.id))
      @merge_request.reset_events_cache

      receive_delayed_notifications
      return true
    end

    return false
  end

  # Mark existing merge request as merged
  # and execute all hooks and notifications
  # Called when you do merge via command line and push code
  # to target branch
  def merge
    merge_request.author_id_of_changes = current_user.id
    merge_request.merge

    create_merge_event(merge_request)
    execute_project_hooks(merge_request)

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

    if Gitlab::Satellite::MergeAction.new(current_user, merge_request).merge!(commit_message)
      merge_request.author_id_of_changes = current_user.id
      merge_request.merge

      create_merge_event(merge_request)
      execute_project_hooks(merge_request)

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

  def notification
    NotificationService.new
  end

  def create_merge_event(merge_request)
    OldEvent.create(
      project: merge_request.target_project,
      target_id: merge_request.id,
      target_type: merge_request.class.name,
      action: OldEvent::MERGED,
      author_id: merge_request.author_id_of_changes
    )
  end

  def execute_project_hooks(merge_request)
    if merge_request.project
      merge_request.project.execute_hooks(merge_request.to_hook_data, :merge_request_hooks)
    end
  end
end
