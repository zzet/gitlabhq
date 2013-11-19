class Emails::Project::PushSummary < Emails::Project::Base
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

    diff_data = load_diff_data(@project.repository.commit(@project.default_branch).id, @push_data['after'], @branch, @project, @user)

    @before_commit = diff_data[:before_commit]
    @after_commit  = diff_data[:after_commit]
    @commits       = diff_data[:commits]
    @commit        = diff_data[:commit]
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

    diff_data = load_diff_data(@push_data['before'], @push_data['after'], @branch, @project, @user)

    @before_commit = diff_data[:before_commit]
    @after_commit  = diff_data[:after_commit]
    @commits       = diff_data[:commits]
    @commit        = diff_data[:commit]
    @diffs         = diff_data[:diffs]
    @refs_are_same = diff_data[:same]
    @suppress_diff = diff_data[:suppress_diff]

    @line_notes    = []

    headers 'X-Gitlab-Entity' => 'group',
      'X-Gitlab-Action' => 'created',
      'X-Gitlab-Source' => 'group',
      'In-Reply-To'     => "project-#{@project.path_with_namespace}-#{@before_commit.id}"

    subject = if @commits.many?
                "[#{@project.path_with_namespace}] [#{@branch}] Pushed #{@commits.count} commits to parent commit #{@before_commit.short_id} [undev gitlab commits]"
              else
                "[#{@project.path_with_namespace}] [#{@branch}] Pushed commit '#{@commit.message.truncate(100, omission: "...")}' to parent commit #{@before_commit.short_id} [undev gitlab commits]"
              end

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: subject)
  end

  private

  def load_diff_data(oldrev, newrev, ref, project, user)
    diff_result = {}

    key_final = "#{user.id}-#{project.id}-#{oldrev}-#{newrev}-final"
    diff_result = Rails.cache.fetch(key_final)

    if diff_result.nil?
      diff_result = {}
      diff_result[:suppress_diff] = project.repository.commits_between(oldrev, newrev).inject(false) { |mem, var| mem || var.diff_suppress? }

      key        = "#{user.id}-#{project.id}-#{oldrev}-#{newrev}"
      before_key = "#{key}-#{oldrev}"
      after_key  = "#{key}-#{newrev}"

      diff_result[:before_commit] = find_commit_in_cache_or_load(before_key, oldrev, project)
      diff_result[:after_commit]  = find_commit_in_cache_or_load(after_key,  newrev, project)

      unless diff_result[:suppress_diff]
        result = Rails.cache.fetch(key)

        if result.nil?
          result = Gitlab::Git::Compare.new(project.repository.raw_repository, oldrev, newrev)
          Rails.cache.write(key, result, expires_in: 20.minutes)

          if result
            diff_result[:branch] = ref
            diff_result[:branch].slice!("refs/heads/")

            diff_result[:commits]       = result.commits
            diff_result[:commit]        = result.commit
            diff_result[:diffs]         = result.diffs
            diff_result[:refs_are_same] = result.same

            diff_result[:suppress_diff] = result.diffs.size > Commit::DIFF_SAFE_FILES
            diff_result[:suppress_diff] ||= result.diffs.inject(0) { |sum, diff| diff.diff.lines.count } > Commit::DIFF_SAFE_LINES

            diff_result[:line_notes]    = []
          end

        end
      end

      Rails.cache.write(key_final, diff_result, expires_in: 20.minutes)
    end
    diff_result
  end

  def find_commit_in_cache_or_load(key, rev, project)
    val = Rails.cache.fetch(key)

    if val.nil?
      val = project.repository.commit(rev)
      Rails.cache.write(key, val, expires_in: 20.minutes)
    end

    val
  end
end
