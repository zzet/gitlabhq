class SubscriptionOptionsMigrate < ActiveRecord::Migration
  def up
    subscriptions.find_each(batch_size: 100) do |subscription|
      model = subscription.target_type.camelize.constantize
      subscription.options = model.watched_sources
      subscription.save
    end

    auto_subscriptions.each do |subscription|
      target = subscription.target_category
      target = 'team' if target == 'user_team'

      Gitlab::Event::Subscription.create_auto_subscription(subscription.user, target)
    end

    auto_subscriptions.delete_all

    adjacent.each do |subscription|
      target = subscription.target
      Gitlab::Event::Subscription.create_auto_subscription(subscription.user,
        subscription.source_category, target)
    end

    adjacent.delete_all
  end

  def down
    subscriptions.update_all(options: [])
    Event::AutoSubscription.delete_all
  end

  private

  def subscriptions
    Event::Subscription.where(action: 'all').where.not(target_type: nil)
  end

  def auto_subscriptions
    Event::Subscription.where.not(target_category: nil).where(source_category: :new)
  end

  def adjacent
    Event::Subscription.where.not(source_category: [:all, :new], target_type: nil)
  end
end
