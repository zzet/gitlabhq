class BaseObserver < ActiveRecord::Observer
  def event_service
    EventCreateService.new
  end

  def log_info message
    Gitlab::AppLogger.info message
  end

  def current_user
    RequestStore.store[:current_user]
  end

  def current_commit
    RequestStore.store[:current_commit]
  end
end
