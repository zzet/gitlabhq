module Profiles::FavouritesHelper
  def favourite_name(entity)
    case entity
    when Project
      entity.name_with_namespace
    when Group
      entity.name
    when Team
      entity.name
    when User
      entity.name
    end
  end

  def link_to_favourite(entity)
    case entity
    when Project
      link_to favourite_name(entity), project_path(entity.path_with_namespace)
    when Group
      link_to favourite_name(entity), group_path(entity.path)
    when Team
      link_to favourite_name(entity), team_path(entity.path)
    when User
      link_to favourite_name(entity), user_path(entity.username)
    end
  end
end
