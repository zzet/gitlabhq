class BaseObserver < ActiveRecord::Observer
  def log_info message
    Gitlab::AppLogger.info message
  end

  def current_user
    Thread.current[:current_user]
  end
end
