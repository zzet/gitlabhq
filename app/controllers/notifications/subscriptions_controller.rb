class Notifications::SubscriptionsController < Notifications::ApplicationController
  before_filter :load_entity, only: [:create, :destroy]

  def create
    SubscriptionService.subscribe(@current_user, :all, @entity, @source)             if @entity
    SubscriptionService.subscribe(@current_user, :all, params[:category], @source)   if @category.blank? && params[:category].present?

    respond_to do |format|
      format.json { head :created }
      format.html { redirect_to profile_subscriptions_path }
    end
  end

  def on_all
    SubscriptionService.subscribe_on_all(@current_user, params[:category], :all, :all) if params[:category]
    redirect_to profile_subscriptions_path
  end

  def from_all
    SubscriptionService.unsubscribe_from_all(@current_user, params[:category], :all, :all) if params[:category]
    redirect_to profile_subscriptions_path
  end

  def on_brave
    @current_user.notification_setting.brave = true

    @current_user.notification_setting.save

    respond_to do |format|
      format.json { head :created }
      format.html { redirect_to profile_subscriptions_path }
    end
  end

  def from_brave
    @current_user.notification_setting.brave = false

    @current_user.notification_setting.save

    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to profile_subscriptions_path }
    end
  end


  def on_owner_subscription
    @current_user.notification_setting.subscribe_if_owner = true

    @current_user.notification_setting.save

    respond_to do |format|
      format.json { head :created }
      format.html { redirect_to profile_subscriptions_path }
    end
  end

  def from_owner_subscription
    @current_user.notification_setting.subscribe_if_owner = false

    @current_user.notification_setting.save

    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to profile_subscriptions_path }
    end
  end

  def on_own_changes
    @current_user.notification_setting.own_changes = true

    @current_user.notification_setting.save

    respond_to do |format|
      format.json { head :created }
      format.html { redirect_to profile_subscriptions_path }
    end
  end

  def from_own_changes
    @current_user.notification_setting.own_changes = false

    @current_user.notification_setting.save

    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to profile_subscriptions_path }
    end
  end

  def on_adjacent_changes
    @current_user.notification_setting.adjacent_changes = true

    @current_user.notification_setting.save

    respond_to do |format|
      format.json { head :created }
      format.html { redirect_to profile_subscriptions_path }
    end
  end

  def from_adjacent_changes
    @current_user.notification_setting.adjacent_changes = false

    @current_user.notification_setting.save

    SubscriptionService.unsubscribe_from_adjacent_sources(@current_user)

    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to profile_subscriptions_path }
    end
  end

  def destroy
    SubscriptionService.unsubscribe(@current_user, :all, @entity, @source)           if @entity
    SubscriptionService.unsubscribe(@current_user, :all, params[:category], @source) if @category

    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to profile_subscriptions_path }
    end
  end

  protected

  def load_entity
    if params[:entity]
      @entity ||= params[:entity][:type].camelize.constantize.find params[:entity][:id]
    end

    @source ||= :all

    @source = params[:source].to_sym.downcase if params[:source]
    @source = :new                            if params[:category]

    if params[:category]
      @category ||= Event::Subscription.by_user(@current_user).by_target_category(params[:category])
    end
  end
end
