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

  private
end
