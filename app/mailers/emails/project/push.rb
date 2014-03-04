class Emails::Project::Push < Emails::Project::Base
  def created_branch_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source_type
    @project      = @event.target
    @repository   = @project.repository
    @push_data    = JSON.load(@event.data).to_hash
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

    @push_data = JSON.load(@event.data).to_hash

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
    @push_data    = JSON.load(@event.data).to_hash
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
    @push_data    = JSON.load(@event.data).to_hash
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
    @push_data    = JSON.load(@event.data).to_hash

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

    headers 'X-Gitlab-Entity' => 'group',
      'X-Gitlab-Action' => 'created',
      'X-Gitlab-Source' => 'group',
      'In-Reply-To'     => "project-#{@project.path_with_namespace}-#{@before_commit.oid}"

    subject = if @commits.many?
                "[#{@project.path_with_namespace}] [#{@branch}] Pushed #{@commits.count} commits to parent commit #{@before_commit.oid[0..10]} [undev gitlab commits]"
              else
                "[#{@project.path_with_namespace}] [#{@branch}] Pushed commit '#{@commit.message.truncate(100, omission: "...")}' to parent commit #{@before_commit.oid[0..10]} [undev gitlab commits]"
              end

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: subject)
  end

  private

  def load_diff_data(oldrev, newrev, ref, project, user)
    diff_result = {}

    diff_result[:branch] = ref
    diff_result[:branch].slice!("refs/heads/")

    r = Rugged::Repository.new(project.repository.path_to_repo)

    diff_result[:before_commit] = r.lookup(oldrev)
    diff_result[:after_commit]  = r.lookup(newrev)
    diff_result[:commit]        = r.lookup(newrev)

    diff = r.diff(oldrev, newrev)
    diff_stat = diff.stat

    diff_result[:suppress_diff] = ((diff_stat.first > 500) || (diff_stat[1] + diff_stat[2] > 10000))

    if diff_result[:suppress_diff]
      diff_result[:commits] = []
      diff_result[:diffs]   = nil
    else
      walker = Rugged::Walker.new(r)
      walker.sorting(Rugged::SORT_REVERSE)
      walker.push(newrev)
      walker.hide(oldrev)
      commit_oids = walker.map {|c| c.oid}
      walker.reset

      diff_result[:commits] = commit_oids.map {|coid| r.lookup(coid) }
      diff_result[:diffs]   = diff
    end

    diff_result
  end
end
