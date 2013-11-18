class Emails::Project::TeamProjectRelationship < Emails::Project::Base
  def assigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @utpr         = @event.source
    @project      = @event.target
    @team         = @utpr.team

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'assigned',
            'X-Gitlab-Source' => 'project-team-relationship',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-team-#{@team.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Team '#{@team.name}' was assigned to project")
  end

  def resigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = JSON.load(@event.data).to_hash
    @team         = Team.find(@source["team_id"])
    @project      = @event.target

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'resigned',
            'X-Gitlab-Source' => 'project-team-relationship',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-team-#{@team.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "[#{@project.path_with_namespace}] Team '#{@team.name}' was resigned from project")
  end
end
