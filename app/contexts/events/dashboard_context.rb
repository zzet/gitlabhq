module Events
  class DashboardContext < Events::BaseContext

    def execute
      available_events = feed.events#(filter)
      user_notifications = current_user.notifications
      events = available_events.limit(params[:limit] || 20).offset(params[:offset] || 0) #.where(id: user_notifications.pluck(:event_id))
    end
  end
end
