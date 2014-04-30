class Profiles::SubscriptionsController < Profiles::ApplicationController
  before_filter :load_entity

  def index
    @subscriptions_by_target_type = Event::Subscription.by_user(@user)
      .with_target_category.group_by(&:target_category)

    @available_subscription_types = Event::Subscription.global_entity_to_subscription

    @subscriptions_by_target_type.keep_if do |t, v|
      @available_subscription_types.include?(t.to_sym)
    end

    @subscriptions = @current_user.personal_subscriptions

    Gitlab::Watchable::MODELS.each do |model|
      count = @subscriptions.where(target_type: model).count
      gon.push({
       "#{model.to_s.underscore.pluralize}" => {
         count: count,
         titles: model.watched_titles,
         descriptions: model.watched_descriptions
       }
      })
    end

    gon.push({
      settings: notification_setting,
      available_subscription_types: @available_subscription_types,
      subscriptions_by_target_type: @subscriptions_by_target_type,
      auto_subscriptions: @current_user.auto_subscriptions
    })
  end

  def create
    if @entity
      head :created

      SubscriptionService.subscribe(@current_user, :all, @entity, :all)
    end
  end

  def destroy
    if @entity
      head :no_content

      SubscriptionService.unsubscribe(@current_user, :all, @entity, :all)
    end
  end

  protected

  def load_entity
    if params[:entity]
      @entity ||= params[:entity][:type].camelize.constantize.find params[:entity][:id]
    end
  end

  def notification_setting
    @notification_setting ||= (@current_user.notification_setting || @current_user.create_notification_setting)
  end
end
