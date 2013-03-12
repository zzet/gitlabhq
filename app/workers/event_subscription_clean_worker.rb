class EventSubscriptionCleanWorker
  def self.call(name, started, finished, unique_id, data)

    gitlab, action, source = name.split "."

    begin
      # TODO. Check, if need to destroy subscriptions while user transfer prject between groups, for example
      if (Event::Subscription.global_entity_to_subscription.include? source.to_sym) && ([:deleted].include? action.to_sym)
        Rails.logger.info "Delete subscription by action: " << name
        Gitlab::Event::Subscription.destroy_subscriprions_by_target(data[:source])
      end
    rescue
      Rails.logger.warn "Error while process destroy subscription on action #{name}"
    end
  end
end
