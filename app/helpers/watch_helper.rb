module WatchHelper
  def watch_button(user, entity)
  end

  def watched_title(user, entity)
    if entity.watched_by? user
      "Unwatch"
    else
      "Watch"
    end
  end

  def watched_class(user, entity)
    if entity.watched_by? user
      "watched"
    else
      ""
    end
  end

  def notification_entity_link(entity)
    case entity
    when Project
      link_to entity.path_with_namespace, project_path(entity)
    when UserTeam
      link_to entity.name, team_path(entity)
    when Group
      link_to entity.name, group_path(entity)
    when User
      link_to entity.name, user_path(entity.username)
    end
  end

  private
end
