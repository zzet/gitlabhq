class Emails::Base < ActionMailer::Base
  layout 'event_notification_email'
  helper :application, :commits, :tree, :gitlab_markdown
  default from: "Gitlab messenger <#{Gitlab.config.gitlab.email_from}>",
          return_path: Gitlab.config.gitlab.email_from

  default_url_options[:host]        = Gitlab.config.gitlab.host
  default_url_options[:protocol]    = Gitlab.config.gitlab.protocol
  default_url_options[:port]        = Gitlab.config.gitlab.port unless Gitlab.config.gitlab_on_standard_port?
  default_url_options[:script_name] = Gitlab.config.gitlab.relative_url_root

  # Set the Message-ID header field
  #
  # local_part - The local part of the message ID
  #
  def set_message_id(local_part)
    headers["Message-ID"] = "<#{local_part}@#{Gitlab.config.gitlab.host}>"
  end

  # Set the References header field
  #
  # local_part - The local part of the referenced message ID
  #
  def set_reference(local_part)
    headers["References"] = "<#{local_part}@#{Gitlab.config.gitlab.host}>"
  end

  def set_x_gitlab_headers(target, source, action, irt, refference = nil, id = nil)
    headers['X-Gitlab-Entity'] = target.to_s
    headers['X-Gitlab-Action'] = action.to_s
    headers['X-Gitlab-Source'] = source.to_s
    headers['In-Reply-To']     = irt

    id = irt.dup unless id
    refference = irt.dup unless refference

    set_message_id(id)
    set_reference(refference)
  end


  # Just send email with 6 seconds delay
  # Wait presence of all objects
  def self.delay
    delay_for(5.seconds)
  end
end
