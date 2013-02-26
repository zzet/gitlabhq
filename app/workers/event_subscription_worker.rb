class EventSubscriptionWorker
  def self.call(name, started, finished, unique_id, data)
    Rails.logger.info "Create subscription by action: " << name

    Gitlab::Event::Subscription.create_subscriprions_by_target(data)
  end
end
