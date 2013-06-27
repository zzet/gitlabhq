module Events
  class DashboardContext < Events::BaseContext

    def execute
      available_events = feed.events(filter)
      user_notifications = current_user.notifications.limit(20).offset(params[:offset] || 0)
      events = available_events.where(id: user_notifications.pluck(:event_id))
    end
  end
end
