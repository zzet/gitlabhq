class Emails::Project::TeamProjectRelationship < Emails::Project::Base
  def assigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utpr         = @event.source
    @project      = @utpr.project
    @team         = @utpr.team

    set_x_gitlab_headers(:project, 'team-project-relationship', :assigned, "project-#{@project.path_with_namespace}-team-#{@team.path}")

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Team '#{@team.name}' was assigned to project")
  end

  def resigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    data          = @event.data
    @project      = Project.find_by_id(data["project_id"])
    @team         = Team.find_by_id(data["team_id"])

    if @project && @team
      set_x_gitlab_headers(:project, 'team-project-relationship', :resigned, "project-#{@project.path_with_namespace}-team-#{@team.path}")

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Team '#{@team.name}' was resigned from project")
    end
  end
end
