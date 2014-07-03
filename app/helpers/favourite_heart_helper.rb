module FavouriteHeartHelper

  def heart_button(user, entity)
  end

  def heart_title(user, entity)
    if entity.favourited_by? user
      "Remove from favourites"
    else
      "Mark as favourite"
    end
  end

  def heart_class(user, entity)
    if entity.favourited_by? user
      "hearted"
    else
      ""
    end
  end

end
