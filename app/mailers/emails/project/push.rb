require 'open3'

class Emails::Project::Push < Emails::Project::Base
  include Gitlab::DiffUtils

  def created_branch_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source_type
    @project      = @event.target
    @repository   = @project.repository
    @push_data    = @event.data
    @branch       = @push_data["ref"]
    @branch.slice!("refs/heads/")

    diff_data = load_diff_data(@project.repository.commit(@project.default_branch).id, @push_data['revafter'], @branch, @project, @user)

    @before_commit = diff_data[:before_commit]
    @after_commit  = diff_data[:after_commit]
    @commits       = diff_data[:commits]
    @commit        = diff_data[:commit] || @after_commit
    @diffs         = diff_data[:diffs]
    @refs_are_same = diff_data[:same]
    @suppress_diff = diff_data[:suppress_diff]

    @line_notes    = []

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created_branch',
            'X-Gitlab-Source' => 'push',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-push-action-#{@event.created_at}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Branch '#{@branch}' was created [undev gitlab commits]")
  end

  def deleted_branch_email(notification)
    @notification = notification

    @event    = @notification.event
    @user     = @event.author
    @source   = @event.source_type
    @project  = @event.target

    @push_data = @event.data

    @branch = @push_data["ref"]
    @branch.slice!("refs/heads/")

    headers 'X-Gitlab-Entity' => 'project',
      'X-Gitlab-Action' => 'deleted_branch',
      'X-Gitlab-Source' => 'push',
      'In-Reply-To'     => "project-#{@project.path_with_namespace}-push-action-#{@event.created_at}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Branch '#{@branch}' was deleted [undev gitlab commits]")
  end

  def created_tag_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source_type
    @project      = @event.target
    @push_data    = @event.data
    @tag          = @push_data["ref"]
    @tag.slice!("refs/tags/")

    headers 'X-Gitlab-Entity' => 'project',
      'X-Gitlab-Action' => 'created_tag',
      'X-Gitlab-Source' => 'push',
      'In-Reply-To'     => "project-#{@project.path_with_namespace}-push-action-#{@event.created_at}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Tag '#{@tag}' was created [undev gitlab commits]")
  end

  def deleted_tag_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source_type
    @project      = @event.target
    @push_data    = @event.data
    @tag          = @push_data["ref"]
    @tag.slice!("refs/tags/")

    @commit = @project.repository.commit(@push_data["before"])

    headers 'X-Gitlab-Entity' => 'project',
      'X-Gitlab-Action' => 'deleted_tag',
      'X-Gitlab-Source' => 'push',
      'In-Reply-To'     => "project-#{@project.path_with_namespace}-push-action-#{@event.created_at}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Tag '#{@tag}' was deleted [undev gitlab commits]")
  end

  def pushed_email(notification)
    @notification = notification

    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source_type
    @project      = @event.target
    @repository   = @project.repository
    @push_data    = @event.data

    @branch = @push_data["ref"]
    @branch.slice!("refs/heads/")

    diff_data = load_diff_data(@push_data['revbefore'], @push_data['revafter'], @branch, @project, @user)

    @before_commit = diff_data[:before_commit]
    @after_commit  = diff_data[:after_commit]
    @commits       = diff_data[:commits]
    @commit        = diff_data[:commit]
    @commit        = @after_commit if @commit.blank?
    @diffs         = diff_data[:diffs]
    @refs_are_same = diff_data[:same]
    @suppress_diff = diff_data[:suppress_diff]

    @line_notes    = []

    headers 'X-Gitlab-Entity' => 'project',
      'X-Gitlab-Action' => 'pushed',
      'X-Gitlab-Source' => 'push',
      'In-Reply-To'     => "project-#{@project.path_with_namespace}-#{@before_commit.oid}"

    subject = if @commits.many?
                "[#{@project.path_with_namespace}] [#{@branch}] Pushed #{@commits.count} commits to parent commit #{@before_commit.oid[0..10]} [undev gitlab commits]"
              else
                "[#{@project.path_with_namespace}] [#{@branch}] Pushed commit '#{@commit.message.force_encoding('UTF-8').delete("\n").truncate(100, omission: "...")}' to parent commit #{@before_commit.oid[0..10]} [undev gitlab commits]"
              end

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: subject)
  end
end
