module API
  # Subscriptions API
  class Subscriptions < Grape::API
    before { authenticate! }

    resource :subscriptions do
      helpers do
        def target_entity(target)
          target[:type].camelize.constantize.find(target[:id])
        end
      end

      # get list of targets which user subscribed
      #
      # Example Request:
      #   GET /subscriptions/targets
      get "targets" do
        type = params[:type]
        model = type.constantize

        #target_id can reference to deleted record
        target_ids = model.ids
        subscriptions = current_user.personal_subscriptions
                                    .where(target_id: target_ids)
                                    .where(target_type: type)
                                    .includes(:target)

        if params[:search].present?
          tids = model.search(params[:search]).pluck(:id)
          subscriptions = subscriptions.where(target_id: tids)
        end

        present :count, subscriptions.count

        subscriptions = paginate subscriptions.order(:id)

        present :targets, subscriptions, with: Entities::TargetSubscription, user: current_user
      end

      # Create subscription (watch)
      #
      # Example Request:
      #   POST /subscriptions
      post do
        target = target_entity(params[:target])
        subscription = Gitlab::Event::Subscription.subscribe(current_user, target)

        present subscription, with: Entities::Subscription
      end

      # Delete subscription (unwatch)
      #
      # Example Request:
      #   DELETE /subscriptions/:type/:id
      delete ":type/:id" do
        target = target_entity({type: params[:type], id: params[:id]})
        Gitlab::Event::Subscription.unsubscribe(current_user, target)

        status 204
      end

      # Bulk subscription options update
      #
      # Example Request:
      #   PATCH /subscriptions/options
      patch "options" do
        options = params[:options] || []

        if params[:targets].is_a?(String) && params[:targets] == 'all'
          sql = options.map{ |option| "'#{option}'"}.join(',')
          current_user.personal_subscriptions.where(target_type: params[:type])
            .update_all("options = ARRAY[#{sql}]")
        else
          params[:targets].each do |target|
            subscription = current_user.personal_subscriptions.find_by(
                target_type: params[:type],
                target_id: target
            )
            Gitlab::Event::Subscription.update_subscription(subscription, options)
          end
        end
        status 204
      end

      # Subscribe to all available targets
      #
      # Example Request:
      #   PATCH /subscriptions/to_all
      post "to_all" do
        Gitlab::Event::Subscription.subscribe_to_all(current_user, params[:subscription_type])
        status 200
      end

      # Unsubscribe from all available targets
      #
      # Example Request:
      #   PATCH /subscriptions/from_all
      post "from_all" do
        model = params[:subscription_type].capitalize
        ids = current_user.personal_subscriptions.where(target_type: model).pluck(:id)

        Event::SubscriptionOption.where(subscription_id: ids).delete_all
        Event::Subscription.where(id: ids).delete_all

        status 200
      end

      # Create adjacent subscription
      #
      # Example Request:
      #   Post /subscriptions/adjacent
      post "adjacent" do
        model = params[:namespace_type].constantize
        namespace = model.find(params[:namespace_id])

        Gitlab::Event::Subscription.create_auto_subscription(@current_user,
                                                             params[:target], namespace)
      end

      # Delete adjacent subscription
      #
      # Example Request:
      #   DELETE /subscriptions/adjacent
      delete "adjacent" do
        current_user.auto_subscriptions.find_by(
            target: params[:target],
            namespace_id: params[:namespace_id],
            namespace_type: params[:namespace_type]
        ).destroy

        status 204
      end

    end
  end
end
