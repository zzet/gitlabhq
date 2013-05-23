class EventNotificationMailPreview < MailView
  extend Gitlab::Event::MailViewDsl

  preview :pushed_project_push_summary_email do
    event = Event.find_by_action :pushed
    Event::Subscription::Notification.find_by_event_id event.id
  end
end
