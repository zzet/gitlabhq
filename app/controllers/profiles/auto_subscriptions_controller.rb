class Profiles::AutoSubscriptionsController < Profiles::ApplicationController
  respond_to :json

  def create
    target = params[:auto_subscription][:target]
    auto_subscription = Gitlab::Event::Subscription.create_auto_subscription(@current_user, target)

    respond_with auto_subscription, location: nil
  end

  def destroy
    auto_subscription = @current_user.auto_subscriptions.find(params[:id])
    auto_subscription.delete

    respond_with auto_subscription
  end
end
