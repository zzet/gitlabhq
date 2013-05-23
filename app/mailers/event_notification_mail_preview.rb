class EventNotificationMailPreview < MailView
  extend Gitlab::Event::MailViewDsl

  preview :pushed_project_push_summary_email do
    user = User.find_by_email "notification_tester@example.com"
    event = ::Event.find_by_author_id user.id
    Event::Subscription::Notification.find_by_event_id event.id
  end
end
