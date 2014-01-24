class EventSubscriptionCreateWorker
  def self.call(name, started, finished, unique_id, data)

    _, action, source = name.split "."

    # For create subscription after create Entity we have Event::AutoSubscription entity
    # We must do next steps:
    #
    # 1) Select Event::AutoSubscription.where(namespace: nil).where(target: source)
    #   1. Check, has subscriber access to created entity?
    #             can?(auto_subscription.subscriber, :"read_#{source}", data[:source]
    #   2. If previuos step - true - create new subscription
    # 2) Select Event::AutoSubscription.where.not(namespace: nil).where(target: source)
    #   1. Also, check has subscriber assess to entity?
    #   2. Check, has subscriber access to namespace?????
    #     a) if true - select namespace and watch namespace type
    #        case namespace
    #        when Group
    #          data[:source].group == namespace
    #        when Team
    #          data[:source].teams.include?(namespace)
    #        else
    #          false
    #        end
    #    b) create subscription
    begin
      # Create subscription on global entity
      if action == "create"
        auto_subscriptions = Event::AutoSubscription.with_target(source).without_namespace
        auto_subscriptions.find_each do |as|
          if as.user.can?(:"read_#{source}", data[:source])
            Rails.logger.info "Create subscription by action: " << name
            Gitlab::Event::Subscription.subscribe(as.user, data[:source])
          end
        end
      end

      # Create Subscriptions on Adjacent entity
      # This finctional available only for autosubscription on Project
      if source == "project"
        if data[:source].group.present? && [:create, :transfer].include?(action.to_sym)
          adjacent_auto_subscriptions = Event::AutoSubscription.with_target(source).with_namespace(data[:source].group)
          adjacent_auto_subscriptions.find_each do |aas|
            if aas.user.can?(:"read_#{aas.namespace.class.name.underscore}", aas.namespace)
              Rails.logger.info "Create subscription by action: " << name
              Gitlab::Event::Subscription.subscribe(aas.user, data[:source])
            end
          end
        end
      end
    rescue
      Rails.logger.warn "Error while process create subscription on action #{name}"
    end
  end
end
