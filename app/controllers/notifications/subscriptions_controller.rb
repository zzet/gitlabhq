class Notifications::SubscriptionsController < Notifications::ApplicationController
  before_filter :load_entity, only: [:create, :destroy]

  def create
    if @entity
      SubscriptionService.subscribe(@current_user, :all, @entity, :all)
      respond_to do |format|
        format.json { head :created }
        format.html { redirect_to profile_subscriptions_path }
      end
    end

    if @category.blank?
      SubscriptionService.subscribe(@current_user, :all, params[:category], :new)
      respond_to do |format|
        format.json { head :created }
        format.html { redirect_to profile_subscriptions_path }
      end
    end
  end

  def on_all
    if params[:category]
      SubscriptionService.subscribe_on_all(@current_user, params[:category], :all, :all)
      redirect_to profile_subscriptions_path
    end
  end

  def from_all
    if params[:category]
      SubscriptionService.unsubscribe_from_all(@current_user, params[:category], :all, :all)
      redirect_to profile_subscriptions_path
    end
  end

  def destroy
    if @entity
      SubscriptionService.unsubscribe(@current_user, :all, @entity, :all)
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to profile_subscriptions_path }
      end
    end

    if @category.present?
      SubscriptionService.unsubscribe(@current_user, :all, params[:category], :new)
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to profile_subscriptions_path }
      end
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
