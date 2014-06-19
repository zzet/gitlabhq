class Emails::Project::Project < Emails::Project::Base
  def created_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source

    set_x_gitlab_headers(:project, :project, :created, "project-#{@project.path_with_namespace}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project was created")
  end

  def updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source
    @changes      = @event.data["previous_changes"]

    set_x_gitlab_headers(:project, :project, :updated, "project-#{@project.path_with_namespace}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Project was updated")
  end

  def deleted_email(notification)
    @notification = notification
    @event        = @notification.event
    data          = @event.data
    @user         = @event.author
    @project      = data
    @namespace    = Namespace.find_by_id(@project["namespace_id"])

    if @namespace
      set_x_gitlab_headers(:project, :project, :deleted, "project-#{@namespace.path}/#{@project["path"]}")

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@namespace.path}/#{@project["path"]}] Project was removed")
    end
  end

  def transfer_email(notification)
    @notification   = notification
    @event          = @notification.event
    @user           = @event.author
    @project        = @event.source
    @owner_changes  = @event.data["owner_changes"]["namespace_id"]
    @old_owner      = Namespace.find(@owner_changes.first)
    @new_owner      = Namespace.find(@owner_changes.last)

    set_x_gitlab_headers(:project, :project, :transfer, "project-#{@old_owner.path}/#{@project["path"]}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@old_owner.path}/#{@project.path}] Project was moved from '#{@old_owner.path}' to '#{@new_owner.path}' namespace [transfered]")
  end

  def members_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: User)
    @new_members  = @project.users_projects.where(user_id: @events.pluck(:target_id))

    set_x_gitlab_headers(:project, :project, :members_added, "project-#{@project.path_with_namespace}-members")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] #{@events.count} users were added to project team")
  end

  def imported_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: User)
    @new_members  = @project.users_projects.where(user_id: @events.pluck(:target_id))

    set_x_gitlab_headers(:project, :project, :members_imported, "project-#{@project.path_with_namespace}-members")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] #{@events.count} users were imported to project team")
  end

  def members_updated_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: User)
    @members      = @project.users_projects.where(user_id: @events.pluck(:target_id))

    set_x_gitlab_headers(:project, :project, :members_updated, "project-#{@project.path_with_namespace}-members")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] #{@events.count} users were updated in project team")
  end

  def members_removed_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: User)
    @members      = User.where(id: @events.pluck(:target_id))

    set_x_gitlab_headers(:project, :project, :members_removed, "project-#{@project.path_with_namespace}-members")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] #{@events.count} users were removed from project team")
  end

  def teams_added_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @project      = @event.source
    @events       = Event.where(parent_event_id: @event.id, target_type: Team)
    @teams        = Team.where(id: @events.pluck(:target_id))

    set_x_gitlab_headers(:project, :project, :teams_added, "project-#{@project.path_with_namespace}-teams")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] #{@events.count} teams were assigned to project team")
  end
end
