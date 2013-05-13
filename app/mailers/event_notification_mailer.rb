class EventNotificationMailer < ActionMailer::Base
  layout 'event_notification_email'
  helper :application, :commits, :tree, :gitlab_markdown
  default from: "Gitlab messeger <#{Gitlab.config.gitlab.email_from}>",
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
    @event = @notification.event
    @user = @event.author
    @group = @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New group #{@source.name} was created [created]")
  end

  # User subscribed on new milestones in project
  def created_project_milestone_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @milestone = @source = @event.source
    @project = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New milestone #{@milestone.title} was created on #{@project.path_with_namespace} [created]")
  end

  def created_issue_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New note #{@source.name} was created on #{@target.name} [created]")
  end

  def created_merge_request_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New note #{@source.name} was created on #{@target.name} [created]")
  end

  def created_note_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New note #{@source.name} was created on #{@target.name} in #{@target.project.name} [created]")
  end

  def created_project_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @project = @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New project #{@project.path_with_namespace} was created [created]")
  end

  def added_project_web_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @web_hook = @source = @event.source
    @project = @target = @event.target

    if @web_hook && @project
      mail(bcc: @notification.subscriber.email, subject: "New project web hook was created on #{@project.name} project [created]")
    end
  end

  def created_project_protected_branch_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New protected_branch #{@source.name} was created on #{@target.name} project [created]")
  end

  def added_project_service_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @service = @source = @event.source
    @project = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New service #{@service.title} was created on #{@project.path_with_namespace} project [created]")
  end

  def created_project_snippet_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @snippet = @source = @event.source
    @project = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New snippet #{@snippet.title} was created on #{@project.path_with_namespace} project [created]")
  end

  def created_project_system_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New system_hook #{@source.name} was created on #{@target.name} project [created]")
  end

  def created_user_user_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @new_user = @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New user #{@source.name} was created [created]")
  end

  def created_user_team_user_team_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @team = @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New Team #{@source.name} was created [created]")
  end

  #
  # Updated action
  #

  def updated_group_group_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @group = @source = @event.source
    @target = @event.target
    @changes = JSON.load(@event.data)["previous_changes"]

    mail(bcc: @notification.subscriber.email, subject: "Group #{@source.name} was updated by #{@user.name} [updated]")
  end

  def updated_group_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utgr = @source = @event.source
    @group = @target = @event.target
    @team = @utgr.user_team

    mail(bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@group.name} project by #{@user.name} [assigned]")
  end

  # User watch issue
  def updated_issue_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Issue #{@source.name} was updated by #{@user.name} [updated]")
  end

  # User watch self changes
  def updated_user_key_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Key #{@source.name} was updated by #{@user.name} in #{@target.name} profile [updated]")
  end

  # User watch MR
  def updated_merge_request_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Merge Request #{@source.name} was updated by #{@user.name} in #{@target.project.name} project [updated]")
  end

  def updated_merge_request_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Note #{@source.name} was updated by #{@user.name} in #{@target.name} merge request [updated]")
  end

  def updated_issue_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Note #{@source.name} was updated by #{@user.name} in #{@target.name} issue [updated]")
  end

  def updated_project_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @project = @source = @event.source
    @target = @event.target
    @changes = JSON.load(@event.data)["previous_changes"]

    mail(bcc: @notification.subscriber.email, subject: "Project #{@source.name} was updated by #{@user.name} [updated]")
  end

  def updated_group_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target
    @changes = JSON.load(@event.data)["previous_changes"]

    mail(bcc: @notification.subscriber.email, subject: "Project #{@source.name} was updated by #{@user.name} in #{@target.name} group [updated]")
  end

  def updated_project_project_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Project Hook #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_project_protected_branch_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Protected Branch #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_project_service_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Service #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_project_snippet_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Snippet #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_project_system_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "System Hook #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_user_user_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @updated_user = @source = @event.source
    @target = @event.target
    @changes = JSON.load(@event.data)["previous_changes"]

    mail(bcc: @notification.subscriber.email, subject: "User #{@updated_user.name} was updated by #{@user.name} [updated]")
  end

  def updated_user_team_user_team_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @team = @source = @event.source
    @target = @event.target
    @changes = JSON.load(@event.data)["previous_changes"]

    mail(bcc: @notification.subscriber.email, subject: "Team #{@team.name} was updated by #{@user.name} [updated]")
  end

  def updated_user_team_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @team = @event.target
    @project = @source.project
    @changes = JSON.load(@event.data)["previous_changes"]

    mail(bcc: @notification.subscriber.email, subject: "Default project access rules for team #{@team.name} were updated by #{@user.name} [updated]")
  end

  def updated_user_team_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utgr = @source = @event.source
    @group = @target = @event.target
    @team = @utgr.user_team

    mail(bcc: @notification.subscriber.email, subject: "Team #{@team.name} assignation to #{@group.name} group was updated by #{@user.name} [assigned]")
  end


  def updated_project_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @project = @event.target
    @team = @source.user_team
    @changes = JSON.load(@event.data)["previous_changes"]

    mail(bcc: @notification.subscriber.email, subject: "Default project access rules for team #{@team.name} was updated by #{@user.name} [updated]")
  end

  def updated_user_team_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @team = @event.target
    @member = @source.user
    @changes = JSON.load(@event.data)["previous_changes"]

    mail(bcc: @notification.subscriber.email, subject: "Membership settings for user #{@member.name} in team #{@team.name} was updated by #{@user.name} [updated]")
  end

  def updated_user_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @member = @event.target
    @team = @source.user_team
    @changes = JSON.load(@event.data)["previous_changes"]

    mail(bcc: @notification.subscriber.email, subject: "Membership settings for user #{@member.name} in team #{@team.name} was updated by #{@user.name} [updated]")
  end

  def updated_user_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @member = @target = @event.target
    @project = @source.project
    @changes = JSON.load(@event.data)["previous_changes"]

    mail(bcc: @notification.subscriber.email, subject: "Permissions for user #{ @member.name } in project #{@project.path_with_namespace} was updated by #{@user.name} [updated]")
  end

  def updated_project_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @project = @target = @event.target
    @member = @source.user
    @changes = JSON.load(@event.data)["previous_changes"]

    mail(bcc: @notification.subscriber.email, subject: "Permissions for user #{ @member.name } in project #{@project.path_with_namespace} was updated by #{@user.name} [updated]")
  end

  #
  # Commented action
  #

  def commented_related_project_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @note = @source = @event.source
    @project = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New note was created by #{@user.name} in #{@project.path_with_namespace} project wall [commented]")
  end

  def commented_project_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @note = @source = @event.source
    @project = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New note was created by #{@user.name} in #{@project.path_with_namespace} project wall [commented]")
  end

  def commented_merge_request_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New note was created by #{@user.name} in #{@target.name} merge request [commented]")
  end

  def commented_issue_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New note was created by #{@user.name} in #{@target.name} issue [commented]")
  end

  def commented_note_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "New note was created by #{@user.name} on #{@target.name} note [commented]")
  end

  #
  # Deleted action
  #

  def deleted_user_key_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @key = @source = JSON.load(@event.data).to_hash
    @updated_user = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Key #{@key["title"]} was deleted from #{@updated_user.name} profile by #{@user.name} user [deleted]")
  end


  def deleted_group_group_email(notification)
    @notification = notification
    @event = @notification.event

    data = JSON.load(@event.data).to_hash

    @user = @event.author
    @group = @source = data
    @target = data

    mail(bcc: @notification.subscriber.email, subject: "Group '#{@group["name"]}' was deleted by #{@user.name} [deleted]")
  end

  def deleted_group_project_email(notification)
    @notification = notification
    @event = @notification.event

    data = JSON.load(@event.data).to_hash

    @user = @event.author
    @project = data
    @group = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Project '#{@project["name"]}' was deleted from #{@group.name} group by #{@user.name} [deleted]")
  end

  def deleted_project_project_email(notification)
    @notification = notification
    @event = @notification.event

    data = JSON.load(@event.data).to_hash

    @user = @event.author
    @project = @source = data
    @target = data

    mail(bcc: @notification.subscriber.email, subject: "Project '#{@project["name"]}' was deleted by #{@user.name} [deleted]")
  end

  def deleted_project_web_hook_email(notification)
    @notification = notification
    @event = @notification.event

    data = JSON.load(@event.data).to_hash

    @user = @event.author
    @project = @event.target
    @web_hook = data

    mail(bcc: @notification.subscriber.email, subject: "Web hook was deleted from '#{@project.name}' project by #{@user.name} [deleted]")

  end

  def deleted_user_team_user_team_email(notification)
    @notification = notification
    @event = @notification.event

    data = JSON.load(@event.data).to_hash

    @user = @event.author
    @team = @source = data
    @target = data

    mail(bcc: @notification.subscriber.email, subject: "Team '#{@team['name']}' was deleted by #{@user.name} [deleted]")
  end

  def deleted_user_user_email(notification)
    @notification = notification
    @event = @notification.event

    data = JSON.load(@event.data).to_hash

    @user = @event.author
    @deleted_user = @source = data
    @target = data

    mail(bcc: @notification.subscriber.email, subject: "User '#{@source['name']}' was deleted by #{@user.name} [deleted]")
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

    mail(bcc: @notification.subscriber.email, subject: "Key #{@key.title} was added to #{@updated_user.name} profile by #{@user.name} user [added]")
  end

  def added_group_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @project = @source = @event.source
    @group = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Project #{@project.path_with_namespace} was added to #{@group.name} group by #{@user.name} [added]")
  end

  def added_project_system_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @project = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "System Hook #{@source.name} was added to #{@target.name} project by #{@user.name} [added]")
  end

  def added_project_project_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @project = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Project Hook #{@source.name} was added to #{@target.name} project by #{@user.name} [added]")
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

    mail(bcc: @notification.subscriber.email, subject: "User #{@member.name} was added to #{@project.path_with_namespace} project team by #{@user.name} [joined]")
  end

  def joined_user_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @up = @source = @event.source
    @project = @up.project
    @member = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "User #{@member.name} was added to #{@project.path_with_namespace} project by #{@user.name} [joined]")
  end

  def joined_user_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utur = @source = @event.source
    @tm = @target = @event.target
    @team = @utur.user_team
    @projects = @team.projects

    mail(bcc: @notification.subscriber.email, subject: "User #{@tm.name} was added to #{@team.name} team by #{@user.name} [joined]")
  end

  def joined_user_team_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author

    @utur = @source = @event.source
    @team = @target = @event.target

    @member = @utur.user
    @projects = @team.projects

    mail(bcc: @notification.subscriber.email, subject: "User #{@member.name} was added to #{@team.name} team by #{@user.name} [joined]")
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
      mail(bcc: @notification.subscriber.email, subject: "User #{@member.name} was removed from #{@project.path_with_namespace} project team by #{@user.name} [left]")
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
      mail(bcc: @notification.subscriber.email, subject: "User #{@member.name} was removed from #{@team.name} team by #{@user.name} [left]")
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
      mail(bcc: @notification.subscriber.email, subject: "User #{@member.name} was removed from #{@project.path_with_namespace} project by #{@user.name} [left]")
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
      mail(bcc: @notification.subscriber.email, subject: "User #{@member.name} was removed from #{@team.name} team by #{@user.name} [left]")
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
      mail(bcc: @notification.subscriber.email, subject: "User #{@member.name} was removed from #{@team.name} team by #{@user.name} [left]")
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

    mail(bcc: @notification.subscriber.email, subject: "Group owner of #{@source.name} group was changed by #{@user.name} [transfered]")
  end

  def transfer_group_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @project = @source = @event.source
    @group = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Project owner of #{@project.name} project in #{@group.name} group was changed by #{@user.name} [transfered]")
  end

  def transfer_project_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Project owner of #{@source.name} project was changed by #{@user.name} [transfered]")
  end

  def transfer_user_team_user_team_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Team owner of #{@source.name} team was changed by #{@user.name} [transfered]")
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

    mail(bcc: @notification.subscriber.email, subject: "Issue #{@source.name} in #{@target.name} project was commented by #{@user.name} [commented_related]")
  end

  def commented_related_project_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Merge Request #{@source.name} in #{@target.name} project was commented by #{@user.name} [commented_related]")
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

    mail(bcc: @notification.subscriber.email, subject: "#{@user.name} cloned #{@target.name} project [cloned]")
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

    mail(bcc: @notification.subscriber.email, subject: "Merge request #{@merge_request.title} was open in #{@project.path_with_namespace} project by #{@user.name} [opened]")
  end

  def opened_project_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @issue = @source = @event.source
    @project = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Issue #{@issue.title} was open in #{@project.path_with_namespace} project by #{@user.name} [opened]")
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

    mail(bcc: @notification.subscriber.email, subject: "Issue #{@source.name} was reopen in #{@target.name} project by #{@user.name} [reopened]")
  end

  def reopened_project_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Merge request #{@source.name} was reopen in #{@target.name} project by #{@user.name} [reopened]")
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

    mail(bcc: @notification.subscriber.email, subject: "Merge request #{@source.name} was merged in #{@target.name} project by #{@user.name} [reopened]")
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

    mail(bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@project.path_with_namespace} project by #{@user.name} [assigned]")
  end

  def assigned_user_team_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utpr = @source = @event.source
    @team = @target = @event.target
    @project = @utpr.project

    mail(bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@project.path_with_namespace} project by #{@user.name} [assigned]")
  end

  def assigned_group_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utgr = @source = @event.source
    @group = @target = @event.target
    @team = @utgr.user_team

    mail(bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@group.name} project by #{@user.name} [assigned]")
  end

  def joined_user_team_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utgr = @source = @event.source
    @team = @target = @event.target
    @group = @utgr.group

    mail(bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@group.name} project by #{@user.name} [assigned]")
  end

  def assigned_user_team_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @utgr = @source = @event.source
    @team = @target = @event.target
    @group = @utgr.group

    mail(bcc: @notification.subscriber.email, subject: "Team #{@team.name} was assigned to #{@group.name} project by #{@user.name} [assigned]")
  end

  def assigned_user_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "#{@target.name} was assigned to #{@source.name} issue by #{@user.name} [assigned]")
  end

  def assigned_user_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "#{@target.name} was assigned to #{@source.name} merge request by #{@user.name} [assigned]")
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

    mail(bcc: @notification.subscriber.email, subject: "Project #{@project.path_with_namespace} was reassigned from #{@team.name} team by #{@user.name} [reassigned]")
  end

  def resigned_user_team_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = JSON.load(@event.data).to_hash
    @project = Project.find_by_id(@source["project_id"])
    @team = @target = @event.target

    if @project
      mail(bcc: @notification.subscriber.email, subject: "Team #{@team.name} was resigned from \"#{@project.path_with_namespace}\" project by #{@user.name} [resigned]")
    end
  end

  def left_user_team_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = JSON.load(@event.data).to_hash
    @group = Group.find(@source["group_id"])
    @team = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Team #{@team.name} was reassigned from \"#{@group.name}\" project by #{@user.name} [reassigned]")
  end

  def resigned_group_user_team_group_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = JSON.load(@event.data).to_hash
    @team = UserTeam.find(@source["user_team_id"])
    @group = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Team #{@team.name} was resigned from \"#{@group.name}\" group by #{@user.name} [resigned]")
  end

  def reassigned_user_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Issue #{@source.name} was reassigned to #{@target.name} user by #{@user.name} [reassigned]")
  end

  def reassigned_user_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "Merge request #{@source.name} was reassigned to #{@target.name} user by #{@user.name} [reassigned]")
  end

  #
  # Push action
  #

  def deleted_branch_project_push_summary_email(notification)
    @notification = notification

    @event = @notification.event
    @user = @event.author
    @source = @event.source_type
    @project = @target = @event.target

    @push_data = JSON.load(@event.data).to_hash

    @branch = @push_data["ref"]
    @branch.slice!("refs/heads/")

    mail(from: @user.email, bcc: @notification.subscriber.email, subject: "[#{@target.path_with_namespace}] Deleted branch '#{@branch}' by #{@user.name} [undev gitlab commits] [pushed]")
  end

  def created_branch_project_push_summary_email(notification)
    @notification = notification

    @event = @notification.event
    @user = @event.author
    @source = @event.source_type
    @project = @target = @event.target

    @push_data = JSON.load(@event.data).to_hash

    @branch = @push_data["ref"]
    @branch.slice!("refs/heads/")

    mail(from: @user.email, bcc: @notification.subscriber.email, subject: "[#{@target.path_with_namespace}] Created new branch '#{@branch}' by #{@user.name} [undev gitlab commits] [pushed]")
  end

  def deleted_tag_project_push_summary_email(notification)
    @notification = notification

    @event = @notification.event
    @user = @event.author
    @source = @event.source_type
    @project = @target = @event.target

    @push_data = JSON.load(@event.data).to_hash

    @tag = @push_data["ref"]
    @tag.slice!("refs/tags/")

    mail(from: @user.email, bcc: @notification.subscriber.email, subject: "[#{@target.path_with_namespace}] Deleted tag '#{@tag}' by #{@user.name} [undev gitlab commits] [pushed]")
  end

  def created_tag_project_push_summary_email(notification)
    @notification = notification

    @event = @notification.event
    @user = @event.author
    @source = @event.source_type
    @project = @target = @event.target

    @push_data = JSON.load(@event.data).to_hash

    @tag = @push_data["ref"]
    @tag.slice!("refs/tags/")

    mail(from: @user.email, bcc: @notification.subscriber.email, subject: "[#{@target.path_with_namespace}] Created new tag '#{@tag}' by #{@user.name} [undev gitlab commits] [pushed]")
  end

  def pushed_project_push_summary_email(notification)
    @notification = notification

    @event = @notification.event
    @user = @event.author
    @source = @event.source_type
    @project = @target = @event.target
    @push_data = JSON.load(@event.data).to_hash
    @branch = @push_data["ref"]
    @branch.slice!("refs/heads/")

    result = Commit.compare(@project, @push_data["before"], @push_data["after"])

    if result
      @before_commit = CommitDecorator.decorate(@project.repository.commit(@push_data["before"]))
      @branch = @push_data["ref"]
      @branch.slice!("refs/heads/")

      @commits       = CommitDecorator.decorate_collection result[:commits]
      @commit        = result[:commit]
      @diffs         = result[:diffs]
      @suppress_diff = result[:diffs].size > Commit::DIFF_SAFE_SIZE
      @refs_are_same = result[:same]
      @line_notes    = []

      mail(from: @user.email, bcc: @notification.subscriber.email, subject: "[#{@target.path_with_namespace}] [#{@branch}] #{@user.name} [undev gitlab commits] [pushed]")
    end
  end
end
