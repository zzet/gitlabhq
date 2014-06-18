class MilestonesService < BaseService

  attr_accessor :current_user, :project, :milestone, :params

  def initialize(user, milestone, params = {}, project = nil)
    @current_user, @project, @milestone = user, project, milestone
    @params = params[:milestone].present? ? params.dup : { milestone: params.dup }
  end

  def create
    milestone = project.milestones.new(params[:milestone])

    if milestone.save
      receive_delayed_notifications
    end

    milestone
  end

  def reopen
    milestone.activate

    milestone
  end

  def close
    milestone.close

    milestone
  end

  def update
    state = params.delete('state_event') || params.delete(:state_event)

    case state
    when 'activate'
      @milestone = reopen
    when 'close'
      @milestone = close
    end

    if params[:milestone].any?
      if @milestone.update(params[:milestone])
        receive_delayed_notifications
      end
    end

    @milestone
  end
end
