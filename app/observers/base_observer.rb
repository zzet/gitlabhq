class BaseObserver < ActiveRecord::Observer
  def log_info message
    Gitlab::AppLogger.info message
  end

  def current_user
    RequestStore.store[:current_user]
  end
end
