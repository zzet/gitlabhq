class Notifications::SubscriptionsController < Notifications::ApplicationController
  before_filter :load_entity

  def create
    if @entity
      SubscriptionService.subscribe(@current_user, :all, @entity, :all)
      head :created
    end

    if @category.blank?
      SubscriptionService.subscribe(@current_user, :all, params[:category], :new)
      head :created
    end
  end

  def destroy
    if @entity
      SubscriptionService.unsubscribe(@current_user, :all, @entity, :all)
      head :no_content
    end

    if @category.present?
      SubscriptionService.unsubscribe(@current_user, :all, params[:category], :new)
      head :no_content
    end
  end

  protected

  def load_entity
    if params[:entity]
      @entity ||= params[:entity][:type].camelize.constantize.find params[:entity][:id]
    end

    if params[:category]
      @category ||= Event::Subscription.by_user(@current_user).by_target_category(params[:category])
    end
  end
end
