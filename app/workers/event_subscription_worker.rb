class EventSubscriptionWorker
  def self.call(name, started, finished, unique_id, data)

    gitlab, action, source = name.split "."

    begin
      if (Event::Subscription.global_entity_to_subscription.include? source.to_sym) && (action.to_sym == :created)
        Rails.logger.info "Create subscription by action: " << name
        Gitlab::Event::Subscription.create_subscriprions_by_target(data[:source])
      end
    rescue
      Rails.logger.warn "Error while process create subscription on action #{name}"
    end
  end
end
