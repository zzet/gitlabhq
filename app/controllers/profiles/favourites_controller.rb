class Profiles::FavouritesController < Profiles::ApplicationController
  def index
    @grouped_favourites = current_user.personal_favourites.group_by(&:entity_type)
  end
end
