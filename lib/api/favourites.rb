module API
  # Favourites API
  class Favourites < Grape::API
    before { authenticate! }

    resource :favourites do
      helpers do
        def target_entity(target)
          target[:type].camelize.constantize.find(target[:id])
        end
      end

      # Create favourite (star)
      #
      # Example Request:
      #   POST /favourites
      post do
        target = target_entity(params[:favourite])
        favourite = FavouritesService.new(current_user).add(target)

        present favourite, with: Entities::Favourite
      end

      # Delete favourite (unstar)
      #
      # Example Request:
      #   DELETE /favourites/:type/:id
      delete ":type/:id" do
        target = target_entity({type: params[:type], id: params[:id]})
        FavouritesService.new(current_user).delete(target)

        status 204
      end
    end
  end
end
