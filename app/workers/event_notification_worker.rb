class EventNotificationWorker
  def self.call(name, started, finished, unique_id, data)
    Rails.logger.info "Triggered action: " << name

    Gitlab::Event.create_events(name, data)
  end
end
