class EventNotificationMailer < ActionMailer::Base
  default from: "Gitlab messeger <#{Gitlab.config.gitlab.email_from}>"

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

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New group #{@source.name} was created [created]")
  end

  # User subscribed on self updates
  def created_user_key_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New key was created for #{@target.name} [created]")
  end

  # User subscribed on new issues in project
  def created_project_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New issue #{@source.name} was created on #{@target.name} [created]")
  end

  # User subscribed on new milestones in project
  def created_project_milestone_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New milestone #{@source.name} was created on #{@target.name} [created]")
  end

  def created_project_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New note #{@source.name} was created on #{@target.name} wall [created]")
  end

  def created_issue_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New note #{@source.name} was created on #{@target.name} [created]")
  end

  def created_merge_request_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New note #{@source.name} was created on #{@target.name} [created]")
  end

  def created_note_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New note #{@source.name} was created on #{@target.name} in #{@target.project.name} [created]")
  end

  def created_group_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @project = @source = @event.source
    @group = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New project #{@source.name} was created on #{@target.name} group [created]")
  end

  def created_project_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @project = @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New project #{@source.name} was created [created]")
  end

  def created_project_project_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New project_hook #{@source.name} was created on #{@target.name} project [created]")
  end

  def created_project_protected_btanch_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New protected_branch #{@source.name} was created on #{@target.name} project [created]")
  end

  def created_project_service_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New service #{@source.name} was created on #{@target.name} project [created]")
  end

  def created_project_snippet_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New snippet #{@source.name} was created on #{@target.name} project [created]")
  end

  def created_project_system_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New system_hook #{@source.name} was created on #{@target.name} project [created]")
  end

  def created_user_user_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @new_user = @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New user #{@source.name} was created [created]")
  end

  def created_user_team_user_team_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @team = @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New Team #{@source.name} was created [created]")
  end

  #def created_user_team_user_team_project_relationship_email(notification)
    #@notification = notification
    #@event = @notification.event
    #@user = @event.author
    #@source = @event.source
    #@target = @event.target

    #mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New issue #{@source.name} was created on #{@target.name} [created]")
  #end

  #def created_project_user_team_project_relationship_email(notification)
    #@notification = notification
    #@event = @notification.event
    #@user = @event.author
    #@source = @event.source
    #@target = @event.target

    #mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New issue #{@source.name} was created on #{@target.name} [created]")
  #end

  #def created_user_user_team_user_relationship_email(notification)
    #@notification = notification
    #@event = @notification.event
    #@user = @event.author
    #@source = @event.source
    #@target = @event.target

    #mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New issue #{@source.name} was created on #{@target.name} [created]")
  #end

  #def created_user_team_user_team_user_relationship_email(notification)
    #@notification = notification
    #@event = @notification.event
    #@user = @event.author
    #@source = @event.source
    #@target = @event.target

    #mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New issue #{@source.name} was created on #{@target.name} [created]")
  #end

  #def created_user_users_project_email(notification)
    #@notification = notification
    #@event = @notification.event
    #@user = @event.author
    #@source = @event.source
    #@target = @event.target

    #mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New issue #{@source.name} was created on #{@target.name} [created]")
  #end

  #def created_project_users_project_email(notification)
    #@notification = notification
    #@event = @notification.event
    #@user = @event.author
    #@source = @event.source
    #@target = @event.target

    #mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New issue #{@source.name} was created on #{@target.name} [created]")
  #end

  #def created_project_wiki_email(notification)
    #@notification = notification
    #@event = @notification.event
    #@user = @event.author
    #@source = @event.source
    #@target = @event.target

    #mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New issue #{@source.name} was created on #{@target.name} [created]")
  #end

  #
  # Updated action
  #

  def updated_group_group_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Group #{@source.name} was updated by #{@user.name} [updated]")
  end

  # User watch issue
  def updated_issue_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Issue #{@source.name} was updated by #{@user.name} [updated]")
  end

  # User watch project
  def updated_project_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Issue #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  # User watch self changes
  def updated_user_key_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Key #{@source.name} was updated by #{@user.name} in #{@target.name} profile [updated]")
  end

  # User watch MR
  def updated_merge_request_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Merge Request #{@source.name} was updated by #{@user.name} in #{@target.project.name} project [updated]")
  end

  # User watch project
  def updated_project_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Merge Request #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  # User watch project
  def updated_project_milestone_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Milestone #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  # User watch project
  def updated_project_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Note #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_merge_request_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Note #{@source.name} was updated by #{@user.name} in #{@target.name} merge request [updated]")
  end

  def updated_issue_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Note #{@source.name} was updated by #{@user.name} in #{@target.name} issue [updated]")
  end

  def updated_project_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @project = @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Project #{@source.name} was updated by #{@user.name} [updated]")
  end

  def updated_group_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Project #{@source.name} was updated by #{@user.name} in #{@target.name} group [updated]")
  end

  def updated_project_project_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Project Hook #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_project_protected_branch_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Protected Branch #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_project_service_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Service #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_project_snippet_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Snippet #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_project_system_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] System Hook #{@source.name} was updated by #{@user.name} in #{@target.name} project [updated]")
  end

  def updated_user_user_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] User #{@source.name} was updated by #{@user.name} [updated]")
  end

  def updated_user_team_user_team_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Team #{@source.name} was updated by #{@user.name} [updated]")
  end

  def updated_user_team_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] UT - P was updated by #{@user.name} [updated]")
  end

  def updated_project_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] UT - P was updated by #{@user.name} [updated]")
  end

  def updated_user_team_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] UT - P was updated by #{@user.name} [updated]")
  end

  def updated_user_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] UT - P was updated by #{@user.name} [updated]")
  end

  def updated_user_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] UT - P was updated by #{@user.name} [updated]")
  end

  def updated_project_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] UT - P was updated by #{@user.name} [updated]")
  end

  #
  # Commented action
  #

  def commented_project_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New note #{@source.name} was created by #{@user.name} in #{@target.name} project wall [commented]")
  end

  def commented_merge_request_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New note #{@source.name} was created by #{@user.name} in #{@target.name} merge request [commented]")
  end

  def commented_issue_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New note #{@source.name} was created by #{@user.name} in #{@target.name} issue [commented]")
  end

  def commented_note_note_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] New note #{@source.name} was created by #{@user.name} on #{@target.name} note [commented]")
  end

  #
  # Deleted action
  #

  def deleted_group_group_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @group = @source = @event.data
    @target = @event.data

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] #{@source["name"]} group was deleted by #{@user.name} [deleted]")
  end

  def deleted_group_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.data
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] #{@source["name"]} project was deleted by #{@user.name} [deleted]")
  end

  def deleted_project_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.data
    @target = @event.data

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] #{@source['name']} user was deleted by #{@user.name} [deleted]")
  end

  def deleted_user_team_user_team_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.data
    @target = @event.data

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] #{@source['name']} team was deleted by #{@user.name} [deleted]")
  end

  def deleted_user_user_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.data
    @target = @event.data

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] #{@source['name']} user was deleted by #{@user.name} [deleted]")
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

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Key #{@source.name} was added to #{@target.name} profile by #{@user.name} user [added]")
  end

  def added_group_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @project = @source = @event.source
    @group = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Project #{@project.name} was added to #{@group.name} group by #{@user.name} [added]")
  end

  def added_project_system_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @project = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] System Hook #{@source.name} was added to #{@target.name} project by #{@user.name} [added]")
  end

  def added_project_project_hook_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @project = @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Project Hook #{@source.name} was added to #{@target.name} project by #{@user.name} [added]")
  end

  #
  # Joined action
  #

  def joined_project_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] User #{@source.user.name} was added to #{@target.name} project by #{@user.name} [joined]")
  end

  def joined_user_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] User #{@target.user.name} was added to #{@source.name} project by #{@user.name} [joined]")
  end

  def joined_user_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] User #{@target.name} was added to #{@source.user_team.name} team by #{@user.name} [joined]")
  end

  #
  # Left action
  #

  def left_project_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] User #{@source.user.name} was removed from #{@target.name} project by #{@user.name} [left]")
  end

  def left_user_users_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] User #{@target.name} was removed from #{@source.project.name} project by #{@user.name} [left]")
  end

  def left_user_user_team_user_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] User #{@target.name} was removed from #{@source.user_team.name} team by #{@user.name} [left]")
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

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Group owner of #{@source.name} group was changed by #{@user.name} [transfered]")
  end

  def transfer_group_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Project owner of #{@source.name} project in #{@target.name} group was changed by #{@user.name} [transfered]")
  end

  def transfer_project_project_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Project owner of #{@source.name} project was changed by #{@user.name} [transfered]")
  end

  def transfer_user_team_user_team_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Team owner of #{@source.name} team was changed by #{@user.name} [transfered]")
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

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Issue #{@source.name} in #{@target.name} project was commented by #{@user.name} [commented_related]")
  end

  def commented_related_project_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Merge Request #{@source.name} in #{@target.name} project was commented by #{@user.name} [commented_related]")
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

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] #{@user.name} cloned #{@target.name} project [cloned]")
  end

  #
  # Opened action
  #

  def opened_project_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Merge request #{@source.name} was open in #{@target.name} project by #{@user.name} [opened]")
  end

  def opened_project_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Issue #{@source.name} was open in #{@target.name} project by #{@user.name} [opened]")
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

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Issue #{@source.name} was reopen in #{@target.name} project by #{@user.name} [reopened]")
  end

  def reopened_project_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Merge request #{@source.name} was reopen in #{@target.name} project by #{@user.name} [reopened]")
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

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Merge request #{@source.name} was merged in #{@target.name} project by #{@user.name} [reopened]")
  end

  #
  # Assigned action
  #

  def assigned_project_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Team #{@source.user_team.name} was assigned to #{@target.name} project by #{@user.name} [assigned]")
  end

  def assigned_user_team_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Team #{@target.name} was assigned to #{@source.project.name} project by #{@user.name} [assigned]")
  end

  def assigned_user_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] #{@target.name} was assigned to #{@source.name} issue by #{@user.name} [assigned]")
  end

  def assigned_user_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] #{@target.name} was assigned to #{@source.name} merge request by #{@user.name} [assigned]")
  end

  #
  # Reassigned action
  #

  def reassigned_project_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Project #{@target.name} was reassigned to #{@source.user_team.name} team by #{@user.name} [reassigned]")
  end

  def reassigned_user_team_user_team_project_relationship_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Team #{@target.name} was reassigned to #{@source.project.name} project by #{@user.name} [reassigned]")
  end

  def reassigned_user_issue_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Issue #{@source.name} was reassigned to #{@target.name} user by #{@user.name} [reassigned]")
  end

  def reassigned_user_merge_request_email(notification)
    @notification = notification
    @event = @notification.event
    @user = @event.author
    @source = @event.source
    @target = @event.target

    mail(bcc: @notification.subscriber.email, subject: "[Gitlab] Merge request #{@source.name} was reassigned to #{@target.name} user by #{@user.name} [reassigned]")
  end

  #
  # Push action
  #

  def pushed_project_push_summary_email(notification)
    p "Start push"
    @notification = notification

    @event = @notification.event
    p @event

    @user = @event.author
    p @user

    @source = @event.source_type
    p @source

    @project = @target = @event.target
    p @project

    @push_data = JSON.load(@event.data).to_hash
    p @push_data

    result = commit.compare(@project, @push_data["before"], @push_data["after"])
    p result

    @commits       = result[:commits]
    @commit        = result[:commit]
    @diffs         = result[:diffs]
    @refs_are_same = result[:same]
    @line_notes    = []

    @commits = CommitDecorator.decorate(@commits)

    mail(from: @user.email, bcc: @notification.subscriber.email, subject: "[Gitlab] [#{@target.name_with_namespace}] [branch] #{@user.name} [undev gitlab commits] [pushed]")
  end

end
