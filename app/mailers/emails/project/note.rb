class Emails::Project::Note < Emails::Project::Base
  def commented_commit_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @note         = @event.source
    @project      = @note.project

    if @note.present?
      @commit_sha = @note.commit_id

      key = "#{@user.id}-#{@project.id}-#{@commit_sha}"

      @commit = Rails.cache.fetch(key)

      if @commit.nil?
        @commit = @note.project.repository.commit(@commit_sha)
        Rails.cache.write(key, @commit, expires_in: 1.hour)
      end

      if @project && @commit
        set_x_gitlab_headers(:project, :note, :commented_commit, "project-#{@project.path_with_namespace}-commit-#{@commit_sha}")

        mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Commit '#{@commit.title}' (sha #{@commit.short_id}) was commented")
      end
    end
  end

  def commented_merge_request_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @note           = @event.source
    @project        = @note.project
    @merge_request  = @note.noteable

    set_x_gitlab_headers(:project, :note, :commented_merge_request, "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.iid}")

    if @note && @project && @merge_request
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@merge_request.title}' (##{@merge_request.iid})")
    end
  end

  def commented_issue_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @note           = @event.source
    @project        = @note.project
    @issue          = @note.noteable

    set_x_gitlab_headers(:project, :note, :commented_issue, "project-#{@project.path_with_namespace}-issue-#{@issue.iid}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] '#{@issue.title}' (##{@issue.iid})")
  end
end
