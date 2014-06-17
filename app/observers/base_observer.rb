class BaseObserver < ActiveRecord::Observer
  def event_service
    EventCreateService.new
  end

  def log_info message
    Gitlab::AppLogger.info message
  end
end
