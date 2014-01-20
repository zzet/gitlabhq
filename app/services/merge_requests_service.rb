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
      @merge_request.reload_code
      @merge_request.mark_as_unchecked
      @merge_request.reset_events_cache

      receive_delayed_notifications
      return true
    end

    return false
  end
end
