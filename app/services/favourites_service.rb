class FavouritesService < BaseService

  attr_accessor :current_user, :favourite, :params

  def initialize(user, params = {})
    @current_user, @paams = user, params.dup
  end

  def add(entity = nil)
    if entity.present?
      star = @current_user.personal_favourites.new(entity_id: entity.id,
                                                   entity_type: entity.class.name)
    else
      star = @current_user.parsonal_favourites.new(params[:favourite])
    end

    star.save

    star
  end

  def delete(entity = nil)
    star = if entity.present?
             @current_user.personal_favourites.find_by(entity_id: entity.id,
                                                       entity_type: entity.class.name)
           else
             @current_user.personal_favourites.find(params[:id])
           end

    if star.present?
      star.destroy
    end

    star
  end
end
