class EventNotificationMailer < ActionMailer::Base
  default from: Gitlab.config.gitlab.email_from

  # Just send email with 3 seconds delay
  def self.delay
    delay_for(2.seconds)
  end

  #
  # Default email
  #

  def default_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Created action
  #

  # User subscribed on new groups
  def created_group_group_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  # Unreal
  #def created_key_key_email(notification)
    #@notification = notification
    #@event = notification.event
    #@user = @event.user
    #@source = @event.source
    #@target = @event.target

    #mail(to: @user.email, subject: "Undefined mail")
  #end

  # User subscribed on self updates
  def created_user_key_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  # User subscribed on new issues (unreal#)
  #def created_issue_issue_email(notification)
    #@notification = notification
    #@event = notification.event
    #@user = @event.user
    #@source = @event.source
    #@target = @event.target

    #mail(to: @user.email, subject: "Undefined mail")
  #end

  # User subscribed on new issues in project
  def created_project_issue_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  # User subscribed on new merge requests in project
  def created_project_merge_request_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  # User subscribed on new milestones in project
  def created_project_milestone_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_project_note_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_issue_note_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_merge_request_note_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_note_note_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_group_project_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_project_project_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_project_project_hook_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_project_protected_btanch_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_project_service_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_project_snippet_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_project_system_hook_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_user_user_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_user_team_user_team_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_user_team_user_team_project_relationship_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_project_user_team_project_relationship_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_user_user_team_user_relationship_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_user_team_user_team_user_relationship_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_user_users_project_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_project_users_project_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  def created_project_wiki_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Updated action
  #

  def updated_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Commented action
  #

  def commented_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Deleted action
  #

  def deleted_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Added action
  #

  def added_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Joined action
  #

  def joined_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Left action
  #

  def left_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Transfer action
  #

  def transfer_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Commented_Related action
  #

  def commented_related_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Pushed action
  #

  def pushed_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Cloned action
  #

  def cloned_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Opened action
  #

  def opened_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Closed action
  #

  def reopened_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Merged action
  #

  def merged_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Assigned action
  #

  def assigned_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

  #
  # Reassigned action
  #

  def reassigned_target_source_email(notification)
    @notification = notification
    @event = notification.event
    @user = @event.user
    @source = @event.source
    @target = @event.target

    mail(to: @user.email, subject: "Undefined mail")
  end

>>>>>>> feature/notifications
end
