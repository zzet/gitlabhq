class EventNotificationWorker
  cattr_accessor :queue

  def self.call(name, started, finished, unique_id, data)
    Rails.logger.info "Triggered action: " << name

    Gitlab::Event::Factory.create_events(name, data)
  end

  def self.subscribed?
    queue.present?
  end
end
