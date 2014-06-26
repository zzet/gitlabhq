class Emails::Team::TeamProjectRelationship < Emails::Team::Base
  def assigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @tpr          = @event.source
    @team         = @tpr.team
    @project      = @tpr.project

    set_x_gitlab_headers(:team, 'team-project-relationship', :assigned, "team-#{@team.path}-project-#{@project.path_with_namespace}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' assignation on '#{@project.path_with_namespace}' project")
  end

  def resigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = @event.data
    @project      = Project.find_by_id(@source["project_id"])
    @team         = Team.find_by_id(@source["team_id"])

    if @project && @team
      set_x_gitlab_headers(:team, 'team-project-relationship', :resigned, "team-#{@team.path}-project-#{@project.path_with_namespace}")

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' assignation on '#{@project.path_with_namespace}' project")
    end
  end
end
