# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class Mailer < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ActionController::UrlWriter

  add_template_helper(MailDiffHelper)
  add_template_helper(ApplicationHelper)
  add_template_helper(RoutingHelper)
  add_template_helper(MailCommitsHelper)

  def signup_notification(user)
    @content_type = "text/html"
    setup_email(user)
    @subject    += I18n.t "mailer.subject"
    @body[:url]  = url_for(
      :controller => 'users',
      :action => 'activate',
      :activation_code => user.activation_code
    )
  end

  def activation(user)
    @content_type = "text/html"
    setup_email(user)
    @subject    += I18n.t "mailer.activated"
  end

  def notification_copy(recipient, sender, subject, body, notifiable, message_id)
    @content_type = "text/html"
    @recipients       =  recipient.email
    @from             = "Gitorious Messenger <no-reply@#{GitoriousConfig['gitorious_host']}>"
    @subject          = "New message: " + sanitize(subject)
    @body[:url]       = url_for({
        :controller => 'messages',
        :action => 'show',
        :id => message_id,
        :host => GitoriousConfig['gitorious_host']
      })

    @body[:body]      = sanitize(body)

    if '1.9'.respond_to?(:force_encoding)
      @body[:recipient] = recipient.title.to_s.force_encoding("utf-8")
      @body[:sender]    = sender.title.to_s.force_encoding("utf-8")
    else
      @body[:recipient] = recipient.title.to_s
      @body[:sender]    = sender.title.to_s
    end

    if notifiable
      @body[:notifiable_url] = build_notifiable_url(notifiable)
    end
  end

  def forgotten_password(user, password_key)
    @content_type = "text/html"
    setup_email(user)
    @subject += I18n.t "mailer.new_password"
    @body[:url] = reset_password_url(password_key, :protocol => GitoriousConfig["scheme"])
  end

  def new_email_alias(email)
    @from       = "Gitorious <no-reply@#{GitoriousConfig['gitorious_host']}>"
    @subject    = "[Gitorious] Please confirm this email alias"
    @sent_on    = Time.now
    @recipients = email.address
    @body[:email] = email
    @body[:url] = confirm_user_alias_url(email.user, email.confirmation_code)
  end

  def message_processor_error(processor, err, message_body = nil)
    @content_type = "text/html"
    subject     "[Gitorious Processor] fail in #{processor.class.name}"
    from        "Gitorious <no-reply@#{GitoriousConfig['gitorious_host']}>"
    recipients  GitoriousConfig['exception_notification_emails']
    body        :error => err, :message => message_body, :processor => processor
  end

  def simple_favorite_notification(recipients, sender, params)
    setup_email(recipients)
    notification_body = params[:notification_body]
    repository = params[:repository]

    @subject = "#{repository.respond_to?(:name) ? "[#{repository.name}] " : ""}#{notification_body.first(900)} [gitorious undev commits]"
    @content_type = "text/html"

    setup_sender(sender)
    @body[:notification_body] = notification_body
  end

  def commit_favorite_notification(recipients, sender, params)
    setup_email(recipients)
    commit = params[:commit]
    message = commit.message
    first_line = message.split("\n").first
    repository = params[:repository]
    position = params[:position] || 1
    project = repository.project
    branch = params[:branch]
    branches = repository.git.git.branch({ :contains => true }, commit.id ).to_a.map { |line| line[ 2 .. -2 ] }.reject{|b| b == branch }

    @subject = "[#{repository.name}/#{branch}]#{"[#{position}]" if position != 0} #{first_line.first(900)} [gitorious undev commits]"
    @from = "#{commit.author.name} <#{commit.author.email}>"
    @content_type = "text/html"

    params[:branches] = branches
    params[:project] = project
    @body.merge!(params)
  end

  def merge_commit_favorite_notification(recipients, sender, params)
    setup_email(recipients)
    commit = params[:commit]
    parents = commit.parents
    message = commit.message
    first_line = message.split("\n").first
    repository = params[:repository]
    position = params[:position] || 1
    project = repository.project
    branch = params[:branch]
    branches = repository.git.git.branch({ :contains => true }, commit.id ).to_a.map { |line| line[ 2 .. -2 ] }.reject{|b| b == branch }

    @subject = "[#{repository.name}/#{branch}]#{"[#{position}]" if position != 0} #{first_line.first(900)} [gitorious undev commits]"
    @from = "#{commit.author.name} <#{commit.author.email}>"
    @content_type = "text/html"

    params[:branches] = branches
    params[:project] = project
    params[:parents] = parents
    @body.merge!(params)
  end

  def create_branch_favorite_notification(recipients, sender, params)
    user = params[:user]
    repository = params[:repository]
    branch = params[:branch]
    commit = params[:commit]
    branches = repository.git.git.branch({ :contains => true }, commit.id ).to_a.map { |line| line[ 2 .. -2 ] }.reject{|b| b == branch }
    setup_email(recipients)
    setup_sender(sender)

    @subject = "[#{repository.name}/#{branch}] #{user.login} created branch #{branch} in #{repository.name} [gitorious undev commits]"
    @content_type = "text/html"
    params[:branches] = branches
    params[:project] = repository.project
    @body.merge!(params)
  end

  def create_tag_favorite_notification(recipients, sender, params)
    user = params[:user]
    repository = params[:repository]
    tag = params[:tag]
    commit = params[:commit]
    parents = commit.parents
    branches = repository.git.git.branch({ :contains => true }, commit.id ).to_a.map { |line| line[ 2 .. -2 ] }
    setup_email(recipients)
    setup_sender(sender)

    @subject = "[#{repository.name}/:#{tag}] #{user.login} created tag #{tag} in #{repository.name} [gitorious undev commits]"
    @content_type = "text/html"
    params[:parents] = parents
    params[:branches] = branches
    params[:project] = repository.project
    @body.merge!(params)
  end

  def delete_tag_favorite_notification(recipients, sender, params)
    user = params[:user]
    repository = params[:repository]
    notification_body = params[:notification_body]
    tag = params[:tag]
    commit = params[:commit]
    setup_email(recipients)
    setup_sender(sender)

    @subject = "[#{repository.name}/:#{tag}] #{user.login} deleted tag #{tag} in #{repository.name} [gitorious undev commits]"
    @content_type = "text/html"
    params[:project] = repository.project
    @body[:notification_body] = notification_body
    @body.merge!(params)
  end


  protected
    def setup_sender(user)
      name = user.fullname || user.login
      @from = "#{name} <#{user.email}>"
    end

    def setup_email(users)
      if users.is_a?(User)
        @recipients = users.email
      elsif users.is_a?(String)
        @bcc = users
      else
        @bcc = users.map(&:email).join(", ")
      end
      @from        = "Gitorious <no-reply@#{GitoriousConfig['gitorious_host']}>"
      @subject     = "[Gitorious] "
      @sent_on     = Time.now
      @body[:user] = users
    end

    def build_notifiable_url(a_notifiable)
      result = case a_notifiable
      when MergeRequest
        project_repository_merge_request_url(a_notifiable.target_repository.project, a_notifiable.target_repository, a_notifiable)
      when Membership
        group_path(a_notifiable.group)
      end

      return result
    end
end
