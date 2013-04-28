class BaseObserver < ActiveRecord::Observer
  def log_info message
    Gitlab::AppLogger.info message
  end
end
