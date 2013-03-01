class Profiles::SubscriptionsController < Profiles::ApplicationController
  before_filter :load_entity

  def index
    @subscriptions_by_target_type = Event::Subscription.by_user(@user).with_target_category.group_by(&:target_category)
    @available_subscription_types = Event::Subscription.global_entity_to_subscription

    @subscriptions_by_target_type.keep_if { |t, v| @available_subscription_types.include?(t.to_sym) }

    @subscriptions = Event::Subscription.by_user(@user).with_target.group_by(&:target_type)
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
end
