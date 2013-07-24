class EventNotificationMailer < ActionMailer::Base
  layout 'event_notification_email'
  helper :application, :commits, :tree, :gitlab_markdown
  default from: "Gitlab messenger <#{Gitlab.config.gitlab.email_from}>",
    return_path: Gitlab.config.gitlab.email_from

  default_url_options[:host]     = Gitlab.config.gitlab.host
  default_url_options[:protocol] = Gitlab.config.gitlab.protocol
  default_url_options[:port]     = Gitlab.config.gitlab.port if Gitlab.config.gitlab_on_non_standard_port?
  default_url_options[:script_name] = Gitlab.config.gitlab.relative_url_root

  # Just send email with 6 seconds delay
  # Wait presence of all objects
  def self.delay
    delay_for(5.seconds)
  end

  #
  # Default email
  #
  def default_email(notification, function)
    Rails.logger.info "unprocessed notification #{notification.inspect}"
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target
    @function = function

    mail(bcc: @notification.subscriber.email, subject: "Undefined mail")
  end

  #
  # Created action
  #

  # User subscribed on new groups
  def created_group_group_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @group        = @event.source

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'group',
            'In-Reply-To'     => "group-#{@group.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New group '#{@group.name}' created")
  end

  # User subscribed on new milestones in project
  def created_project_milestone_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @milestone    = @event.source
    @project      = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'milestone'

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New milestone #{@milestone.title} was created on #{@project.path_with_namespace} [created]")
  end

  def created_issue_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New note #{@source.name} was created on #{@target.name} [created]")
  end

  def created_merge_request_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New note was created on #{@target.name} [created]")
  end

  def created_note_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New note was created in #{@target.project.name} [created]")
  end

  def created_project_project_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'project'

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New project '#{@project.path_with_namespace}' created")
  end

  def added_project_web_hook_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @web_hook     = @event.source
    @project      = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'web_hook',
            'In-Reply-To'     => "#{@project.path_with_namespace}-web-hook-#{@web_hook.id}"

    if @web_hook && @project
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] New project web hook added")
    end
  end

  def created_project_protected_branch_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @branch       = @event.source
    @project      = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'protected_branch',
            'In-Reply-To'     => "#{@project.path_with_namespace}-branch-#{@branch.name}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] [#{@branch.name}] Branch status was changed to protected mode")
  end

  def added_project_service_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @service      = @event.source
    @project      = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'service',
            'In-Reply-To'     => "#{@project.path_with_namespace}-service-#{@service.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Service '#{@service.title}' was added to project")
  end

  def created_project_snippet_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @snippet      = @event.source
    @project      = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'snippet',
            'In-Reply-To'     => "#{@project.path_with_namespace}-snippet-#{@snippet.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] New snippet '#{@snippet.title}' was created")
  end

  def created_project_system_hook_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @system_hook  = @event.source
    @project      = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'system_hook',
            'In-Reply-To'     => "#{@project.path_with_namespace}-system-hook-#{@system_hook.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] New system hook '#{@system_hook.name}' was added to project")
  end

  def created_user_user_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @new_user     = @event.source

    headers 'X-Gitlab-Entity' => 'user',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'user',
            'In-Reply-To'     => "user-#{@new_user.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New user '#{@source.name}' was created")
  end

  def created_user_team_user_team_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source
    @target       = @event.target

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'created',
            'X-Gitlab-Source' => 'team',
            'In-Reply-To'     => "team-#{@team.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New team '#{@team.name}' was created")
  end

  #
  # Updated action
  #

  def updated_group_group_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @group        = @event.source
    @target       = @event.target
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'group',
            'In-Reply-To'     => "group-#{@group.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Group '#{@source.name}' was updated")
  end

  def updated_group_user_team_group_relationship_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utgr         = @event.source
    @group        = @event.target
    @team         = @utgr.user_team
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'group-team-relationship',
            'In-Reply-To'     => "group-#{@group.path}-team-#{@team.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Assigment team '#{@team.name}' to '#{@group.name}' group was updated")
  end

  # User watch issue
  def updated_issue_issue_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @issue        = @event.source
    @project      = @issue.project
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'issue',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'issue',
            'In-Reply-To'     => "issue-#{@issue.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Issue ##{@issue.id} '#{@issue.name}' was updated")
  end

  # User watch self changes
  def updated_user_key_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @key          = @event.source
    @updated_user = @event.target
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'user',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'key',
            'In-Reply-To'     => "user-#{@updated_user.username}-key-#{@key.title}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Key '#{@key.title}' was updated in #{@updated_user.name} profile")
  end

  # User watch MR
  def updated_merge_request_merge_request_email(notification)
    @notification  = notification
    @event         = @notification.event
    @user          = @event.author
    @merge_request = @event.source
    @project       = @merge_request.project
    @changes       = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'merge_request',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'merge_request',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Merge Request ##{@merge_request.id} '#{@source.title}' was updated")
  end

  def updated_merge_request_note_email(notification)
    @notification  = notification
    @event         = @notification.event
    @user          = @event.author
    @note          = @event.source
    @merge_request = @event.target
    @project       = @merge_request.project
    @changes       = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'note',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'merge_request',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.id}-note-#{@note.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Comment was updated in merge request ##{@merge_request.id} '#{@merge_request.title}'")
  end

  def updated_issue_note_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @note         = @event.source
    @issue        = @event.target
    @project      = @issue.project
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'note',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'issue',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-issue-#{@issue.id}-note-#{@note.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Comment was updated in issue ##{@issue.id} '#{@issue.title}'")
  end

  def updated_project_project_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'project',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project was updated")
  end

  def updated_group_project_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source
    @group        = @event.target
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'project',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project was updated")
  end

  def updated_project_project_hook_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project_hook = @event.source
    @project      = @event.target
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'group',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'project',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-project_hook-#{@project_hook.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project Hook '#{@project_hook.name}' was updated")
  end

  def updated_project_protected_branch_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Protected Branch #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_project_service_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Service #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_project_snippet_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Snippet #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_project_system_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "System Hook #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_user_user_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @updated_user = @event.source
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'user',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'user',
            'In-Reply-To'     => "user-#{@updated_user.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@updated_user.name}' was updated")
  end

  def updated_user_team_user_team_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @team         = @event.source
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'team',
            'In-Reply-To'     => "team-#{@team.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' was updated")
  end

  def updated_user_team_user_team_project_relationship_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utpr         = @event.source
    @team         = @event.target
    @project      = @utpr.project
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'team-project-relationship',
            'In-Reply-To'     => "team-#{@team.path}-project-#{@project.path_with_namespace}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Default project access rules for team '#{@team.name}' were updated")
  end

  def updated_user_team_user_team_group_relationship_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utgr         = @event.source
    @group        = @event.target
    @team         = @utgr.user_team
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'team-group-relationship',
            'In-Reply-To'     => "team-#{@team.path}-group-#{@group.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Assignation of team '#{@team.name}' to '#{@group.name}' group was updated")
  end


  def updated_project_user_team_project_relationship_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utpr         = @event.source
    @project      = @event.target
    @team         = @utpr.user_team
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'team-project-relationship',
            'In-Reply-To'     => "team-#{@team.path}-project-#{@project.path_with_namespace}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Default project access rules for team '#{@team.name}' was updated")
  end

  def updated_user_team_user_team_user_relationship_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utur         = @event.source
    @team         = @event.target
    @member       = @utur.user
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'team-user-relationship',
            'In-Reply-To'     => "team-#{@team.path}-user-#{@member.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Membership settings for user '#{@member.name}' in team '#{@team.name}' was updated")
  end

  def updated_user_user_team_user_relationship_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source
    @member       = @event.target
    @team         = @source.user_team
    @changes      = JSON.load(@event.data).to_hash["previous_changes"]

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'team-user-relationship',
            'In-Reply-To'     => "team-#{@team.path}-user-#{@member.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Membership settings for user #{@member.name} in team #{@team.name} was updated")
  end

  def updated_user_users_project_email(notification)
    @notification        = notification
    @event               = @notification.event
    @user                = @event.author
    @upr                 = @event.source
    @member              = @target = @event.target
    @project             = @upr.project
    @changes             = JSON.load(@event.data).to_hash["previous_changes"]
    @previous_permission = UsersProject.access_roles.key(@changes.first.first)
    @current_permission  = UsersProject.access_roles.key(@changes.first.last)

    headers 'X-Gitlab-Entity' => 'user',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'project-user-relationship',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-user-#{@member.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Permissions for user '#{ @member.name }' in project '#{@project.path_with_namespace}' was updated")
  end

  def updated_project_users_project_email(notification)
    @notification         = notification
    @event                = @notification.event
    @user                 = @event.author
    @upr                  = @event.source
    @project              = @event.target
    @member               = @upr.user
    @changes              = JSON.load(@event.data).to_hash["previous_changes"]
    @previous_permission  = UsersProject.access_roles.key(@changes.first.first)
    @current_permission   = UsersProject.access_roles.key(@changes.first.last)

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'updated',
            'X-Gitlab-Source' => 'project-user-relationship',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-user-#{@member.username}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Permissions for user '#{ @member.name }' was updated")
  end

  #
  # Commented action
  #

  def commented_commit_project_note_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @note         = @event.source
    @project      = @event.target

    if @note.present?
      @commit_sha = @note.commit_id

      key = "#{@user.id}-#{@project.id}-#{@commit_sha}"

      @commit = Rails.cache.fetch(key)

      if @commit.nil?
        @commit = @note.project.repository.commit(@commit_sha)
        Rails.cache.write(key, @commit, expires_in: 1.hour)
      end

      headers 'X-Gitlab-Entity' => 'project/commit',
              'X-Gitlab-Action' => 'commented',
              'X-Gitlab-Source' => 'note',
              'In-Reply-To'     => "project-#{@project.path_with_namespace}-commit-#{@commit_sha}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Commit '#{@commit.title}' (sha #{@commit.short_id}) commented")
    end
  end

  def commented_merge_request_project_note_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @note           = @event.source
    @merge_request  = @note.noteable
    @project        = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'commented',
            'X-Gitlab-Source' => 'note',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.id}"

    if @note && @project && @merge_request
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Merge Request ##{@merge_request.id} '#{@merge_request.title}' commented")
    end
  end

  def commented_project_note_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @note         = @event.source
    @project      = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'commented',
            'X-Gitlab-Source' => 'note',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-wall"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] New note was created on project wall")
  end

  def commented_merge_request_note_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @note           = @source = @event.source
    @merge_request  = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'commented',
            'X-Gitlab-Source' => 'note',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-merge_request-#{@merge_request.id}"

    if @note && @project && @merge_request
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Merge Request ##{@merge_request.id} '#{@merge_request.title}' commented")
    end
  end

  def commented_issue_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New note was created by #{@user.name} in #{@target.name} issue [commented]")
  end

  def commented_note_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "New note was created by #{@user.name} on #{@target.name} note [commented]")
  end

  #
  # Deleted action
  #

  def deleted_user_key_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @key          = @source = JSON.load(@event.data).to_hash
    @updated_user = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Key #{@key["title"]} was deleted from #{@updated_user.name} profile by #{@user.name} user [deleted]")
  end


  def deleted_group_group_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = JSON.load(@event.data).to_hash
    @user         = @event.author
    @group        = @source = data
    @target       = data

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Group '#{@group["name"]}' was deleted by #{@user.name} [deleted]")
  end

  def deleted_user_team_user_relationship_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author

    data = JSON.load(@event.data).to_hash

    @user = User.find_by_id(data["user_id"])
    @team = UserTeam.find_by_id(data["user_team_id"])

    if @user && @team
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User #{@user.name} was removed from #{@team.name} team by #{@user.name} [deleted]")
    end
  end

  def deleted_user_team_group_relationship_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author

    data = JSON.load(@event.data).to_hash

    @group = Group.find_by_id(data["group_id"])
    @team = UserTeam.find_by_id(data["user_team_id"])

    if @group && @team
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was resigned from #{@group.name} group by #{@user.name} [resigned]")
    end
  end

  def deleted_user_team_project_relationship_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author

    data = JSON.load(@event.data).to_hash

    @project = Project.find_by_id(data["project_id"])
    @team = UserTeam.find_by_id(data["user_team_id"])

    if @project && @team
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was resigned from #{@project.path_with_namespace} group by #{@user.name} [resigned]")
    end
  end

  def deleted_group_project_email(notification)
    @notification = notification
    @event = @notification.event

    data = JSON.load(@event.data).to_hash

    @user = @event.author
    @project = data
    @group = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Project '#{@project["name"]}' was deleted from #{@group.name} group by #{@user.name} [deleted]")
  end

  def deleted_project_project_email(notification)
    @notification = notification
    @event = @notification.event

    data = JSON.load(@event.data).to_hash

    @user = @event.author
    @project = @source = data
    @target = data

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Project '#{@project["name"]}' was deleted by #{@user.name} [deleted]")
  end

  def deleted_project_web_hook_email(notification)
    @notification = notification
    @event = @notification.event

    data = JSON.load(@event.data).to_hash

    @user = @event.author
    @project = @event.target
    @web_hook = data

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Web hook was deleted from '#{@project.name}' project by #{@user.name} [deleted]")

  end

  def deleted_user_team_user_team_email(notification)
    @notification = notification
    @event = @notification.event

    data = JSON.load(@event.data).to_hash

    @user = @event.author
    @team = @source = data
    @target = data

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team['name']}' was deleted by #{@user.name} [deleted]")
  end

  def deleted_user_user_email(notification)
    @notification = notification
    @event = @notification.event

    data = JSON.load(@event.data).to_hash

    @user = @event.author
    @deleted_user = @source = data
    @target = data

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User '#{@source['name']}' was deleted by #{@user.name} [deleted]")
  end

  #
  # Added action
  #

  def added_user_key_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @key = @source = @event.source
    @updated_user = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Key #{@key.title} was added to #{@updated_user.name} profile by #{@user.name} user [added]")
  end

  def added_group_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @project = @source = @event.source
    @group = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Project #{@project.path_with_namespace} was added to #{@group.name} group by #{@user.name} [added]")
  end

  def added_project_system_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @project = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "System Hook #{@source.name} was added to #{@target.name} project by #{@user.name} [added]")
  end

  def added_project_project_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @project = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Project Hook #{@source.name} was added to #{@target.name} project by #{@user.name} [added]")
  end

  #
  # Joined action
  #

  def joined_project_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @up = @source = @event.source
    @project = @target = @event.target
    @member = @up.user

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User #{@member.name} was added to #{@project.path_with_namespace} project team by #{@user.name} [joined]")
  end

  def joined_user_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @up = @source = @event.source
    @project = @up.project
    @member = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User #{@member.name} was added to #{@project.path_with_namespace} project by #{@user.name} [joined]")
  end

  def joined_user_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utur = @source = @event.source
    @tm = @target = @event.target
    @team = @utur.user_team
    @projects = @team.projects

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User #{@tm.name} was added to #{@team.name} team by #{@user.name} [joined]")
  end

  def joined_user_team_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author

    @utur = @source = @event.source
    @team = @target = @event.target

    @member = @utur.user
    @projects = @team.projects

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User #{@member.name} was added to #{@team.name} team by #{@user.name} [joined]")
  end

  #
  # Left action
  #

  def left_project_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = JSON.load(@event.data)
    @project = @target = @event.target
    @member = User.find(@source["user_id"])
    if @member && @project
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User #{@member.name} was removed from #{@project.path_with_namespace} project team by #{@user.name} [left]")
    end
  end

  def left_user_team_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event

    @source = JSON.load(@event.data)

    @user = @event.author
    @team = @target = @event.target
    @member = User.find(@source["user_id"])

    if @team && @user
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User #{@member.name} was removed from #{@team.name} team by #{@user.name} [left]")
    end
  end

  def left_user_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = JSON.load(@event.data)
    @member = @target = @event.target
    @project = Project.find(@source["project_id"])
    if @project
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User #{@member.name} was removed from #{@project.path_with_namespace} project by #{@user.name} [left]")
    end
  end

  def left_user_team_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = JSON.load(@event.data)

    @team = @target = @event.target
    @member = User.find(@source["user_id"])

    if @team
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User #{@member.name} was removed from #{@team.name} team by #{@user.name} [left]")
    end
  end

  def left_user_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = JSON.load(@event.data)
    @member = @target = @event.target

    @team = UserTeam.find(@source["user_team_id"])

    if @member
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User #{@member.name} was removed from #{@team.name} team by #{@user.name} [left]")
    end
  end

  #
  # Transfer action
  #

  def transfer_group_group_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Group owner of #{@source.name} group was changed by #{@user.name} [transfered]")
  end

  def transfer_group_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @project = @source = @event.source
    @group = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Project owner of #{@project.name} project in #{@group.name} group was changed by #{@user.name} [transfered]")
  end

  def transfer_project_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @project = @source = @event.source

    @owner_changes = JSON.load(@event.data).to_hash["owner_changes"]["namespace_id"]
    @old_owner = Namespace.find(@owner_changes.first)
    @new_owner = Namespace.find(@owner_changes.last)

    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@old_owner.path}/#{@project.path}] Project was moved from '#{@old_owner.path}' to '#{@new_owner.path}' namespace [transfered]")
  end

  def transfer_user_team_user_team_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team owner of #{@source.name} team was changed by #{@user.name} [transfered]")
  end

  #
  # Commented_Related action
  #

  def commented_related_project_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Issue #{@source.name} in #{@target.name} project was commented by #{@user.name} [commented_related]")
  end

  def commented_related_project_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Merge Request #{@source.name} in #{@target.name} project was commented by #{@user.name} [commented_related]")
  end

  #
  # Cloned action
  #

  def cloned_project_source_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "#{@user.name} cloned #{@target.name} project [cloned]")
  end

  #
  # Opened action
  #

  def opened_project_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @merge_request = @source = @event.source
    @project = @target = @event.target

    headers 'In-Reply-To' => "MergeRequest ##{@merge_request.id}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Merge request '#{@merge_request.title}' was opened [opened]")
  end

  def opened_project_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @issue = @source = @event.source
    @project = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Issue #{@issue.title} was open in #{@project.path_with_namespace} project by #{@user.name} [opened]")
  end

  #
  # Reopened action
  #

  def reopened_project_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Issue #{@source.name} was reopen in #{@target.name} project by #{@user.name} [reopened]")
  end

  def reopened_project_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Merge request #{@source.name} was reopen in #{@target.name} project by #{@user.name} [reopened]")
  end

  #
  # Merged action
  #

  def merged_project_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Merge request #{@source.name} was merged in #{@target.name} project by #{@user.name} [reopened]")
  end

  #
  # Assigned action
  #

  def assigned_project_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utpr = @source = @event.source
    @project = @target = @event.target
    @team = @utpr.user_team

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@project.path_with_namespace} project by #{@user.name} [assigned]")
  end

  def assigned_user_team_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utpr = @source = @event.source
    @team = @target = @event.target
    @project = @utpr.project

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@project.path_with_namespace} project by #{@user.name} [assigned]")
  end

  def created_user_team_project_relationship_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utpr = @source = @event.source
    @project = @utpr.project
    @team = @utpr.user_team

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@project.path_with_namespace} project by #{@user.name} [assigned]")
  end

  def updated_user_team_user_relationship_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utur = @source = @event.source
    @updated_user = @utur.user
    @team = @utur.user_team
    @data = JSON.load(@event.data).to_hash
    @changes = @data["previous_changes"]

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team membership in #{@team.name} team for #{@updated_user.name} user was updated by #{@user.name} [updated]")
  end

  def updated_user_team_group_relationship_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utgr = @source = @event.source
    @group = @utgr.group
    @team = @utgr.user_team

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} assignation to #{@group.name} group was updated by #{@user.name} [assigned]")
  end

  def created_user_team_user_relationship_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utur = @source = @event.source
    @added_user = @utur.user
    @team = @utur.user_team
    @projects = @team.projects.with_user(@notification.subscriber)

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "User #{@added_user.name} was added to #{@team.name} team by #{@user.name} [joined]")
  end

  def created_user_team_group_relationship_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utgr = @source = @event.source
    @group = @utgr.group
    @team = @utgr.user_team

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@group.name} group by #{@user.name} [assigned]")
  end

  def assigned_group_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utgr = @source = @event.source
    @group = @target = @event.target
    @team = @utgr.user_team

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@group.name} group by #{@user.name} [assigned]")
  end

  def joined_user_team_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utgr = @source = @event.source
    @team = @target = @event.target
    @group = @utgr.group

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@group.name} project by #{@user.name} [assigned]")
  end

  def assigned_user_team_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utgr = @source = @event.source
    @team = @target = @event.target
    @group = @utgr.group

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@group.name} project by #{@user.name} [assigned]")
  end

  def assigned_user_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "#{@target.name} was assigned to #{@source.name} issue by #{@user.name} [assigned]")
  end

  def assigned_user_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "#{@target.name} was assigned to #{@source.name} merge request by #{@user.name} [assigned]")
  end

  #
  # Reassigned action
  #

  def reassigned_project_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = JSON.load(@event.data).to_hash
    @team = UserTeam.find(@source["user_team_id"])
    @project = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Project #{@project.path_with_namespace} was reassigned from #{@team.name} team by #{@user.name} [reassigned]")
  end

  def resigned_user_team_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = JSON.load(@event.data).to_hash
    @project = Project.find_by_id(@source["project_id"])
    @team = @target = @event.target

    if @project
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was resigned from \"#{@project.path_with_namespace}\" project by #{@user.name} [resigned]")
    end
  end

  def left_user_team_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = JSON.load(@event.data).to_hash
    @group = Group.find(@source["group_id"])
    @team = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was reassigned from \"#{@group.name}\" project by #{@user.name} [reassigned]")
  end

  def resigned_group_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = JSON.load(@event.data).to_hash
    @team = UserTeam.find(@source["user_team_id"])
    @group = @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team #{@team.name} was resigned from \"#{@group.name}\" group by #{@user.name} [resigned]")
  end

  def reassigned_user_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Issue #{@source.name} was reassigned to #{@target.name} user by #{@user.name} [reassigned]")
  end

  def reassigned_user_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Merge request #{@source.name} was reassigned to #{@target.name} user by #{@user.name} [reassigned]")
  end

  #
  # Push action
  #

  def deleted_branch_project_push_summary_email(notification)
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

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@target.path_with_namespace}] Branch '#{@branch}' was deleted [undev gitlab commits]")
  end

  def created_branch_project_push_summary_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source_type
    @project      = @event.target
    @push_data    = JSON.load(@event.data).to_hash
    @branch       = @push_data["ref"]
    @branch.slice!("refs/heads/")

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created_branch',
            'X-Gitlab-Source' => 'push',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-push-action-#{@event.created_at}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@target.path_with_namespace}] Branch '#{@branch}' was created [undev gitlab commits]")
  end

  def deleted_tag_project_push_summary_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source_type
    @project      = @target = @event.target
    @push_data    = JSON.load(@event.data).to_hash
    @tag          = @push_data["ref"]
    @tag.slice!("refs/tags/")

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'deleted_tag',
            'X-Gitlab-Source' => 'push',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-push-action-#{@event.created_at}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@target.path_with_namespace}] Tag '#{@tag}' was deleted [undev gitlab commits]")
  end

  def created_tag_project_push_summary_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source_type
    @project      = @target = @event.target
    @push_data    = JSON.load(@event.data).to_hash
    @tag          = @push_data["ref"]
    @tag.slice!("refs/tags/")

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'created_tag',
            'X-Gitlab-Source' => 'push',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-push-action-#{@event.created_at}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@target.path_with_namespace}] Tag '#{@tag}' was created [undev gitlab commits]")
  end

  def pushed_project_push_summary_email(notification)
    @notification = notification

    @event        = @notification.event
    @user         = @event.author
    @source       = @event.source_type
    @project      = @event.target
    @repository   = @project.repository
    @push_data    = JSON.load(@event.data).to_hash

    key = "#{@user.id}-#{@project.id}-#{@push_data["before"]}-#{@push_data["after"]}"

    result = Rails.cache.fetch(key)

    if result.nil?
      result = Gitlab::Git::Compare.new(@project.repository, @push_data["before"], @push_data["after"])
      Rails.cache.write(key, result, expires_in: 1.hour)
    end

    if result

      before_key = "#{key}-#{@push_data["before"]}"
      @before_commit = Rails.cache.fetch(before_key)

      if @before_commit.nil?
        @before_commit = @project.repository.commit(@push_data["before"])
        Rails.cache.write(before_key, @before_commit, expires_in: 1.hour)
      end

      after_key = "#{key}-#{@push_data["after"]}"
      @after_commit = Rails.cache.fetch(after_key)

      if @after_commit.nil?
        @after_commit = @project.repository.commit(@push_data["after"])
        Rails.cache.write(after_key, @after_commit, expires_in: 1.hour)
      end

      @branch = @push_data["ref"]
      @branch.slice!("refs/heads/")

      @commits       = result.commits
      @commit        = result.commit
      @diffs         = result.diffs
      @refs_are_same = result.same

      @suppress_diff = result.diffs.size > Commit::DIFF_SAFE_SIZE
      @suppress_diff ||= result.diffs.inject(0) { |sum, diff| diff.diff.lines.count } > Commit::DIFF_SAFE_LINES_COUNT

      @line_notes    = []

      headers 'X-Gitlab-Entity' => 'group',
              'X-Gitlab-Action' => 'created',
              'X-Gitlab-Source' => 'group',
              'In-Reply-To'     => "project-#{@project.path_with_namespace}-#{@before_commit.id}"

      subject = if @commits.many?
        "[#{@target.path_with_namespace}] [#{@branch}] Pushed commit '#{@commit.title}' to parent commit #{@before_commit.short_id} [undev gitlab commits]"
      else
        "[#{@target.path_with_namespace}] [#{@branch}] Push with #{@commits.count} commits to parent commit #{@before_commit.short_id} [undev gitlab commits]"
      end

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: subject)
    end
  end
end
