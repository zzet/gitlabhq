class EventNotificationMailer < ActionMailer::Base
  layout 'event_notification_email'
  helper :application, :commits, :tree, :gitlab_markdown
  default from: "Gitlab messenger <#{Gitlab.config.gitlab.email_from}>",
    return_path: Gitlab.config.gitlab.email_from

  default_url_options[:host]     = Gitlab.config.gitlab.host
  default_url_options[:protocol] = Gitlab.config.gitlab.protocol
  default_url_options[:port]     = Gitlab.config.gitlab.port unless Gitlab.config.gitlab_on_standard_port?
  default_url_options[:script_name] = Gitlab.config.gitlab.relative_url_root

  # Just send email with 6 seconds delay
  # Wait presence of all objects
  def self.delay
    delay_for(5.seconds)
  end
end
