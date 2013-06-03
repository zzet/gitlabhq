if defined?(MailView)
  class EventNotificationMailPreview < MailView
    extend Gitlab::Event::MailViewDsl

    preview :pushed_project_push_summary_email, :pushed_project_push_summary
  end
end
