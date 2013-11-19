class Emails::Team::TeamProjectRelationship < Emails::Team::Base
  def assigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @tpr          = @event.source
    @team         = @tpr.team
    @project      = @tpr.project

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'assigned',
            'X-Gitlab-Source' => 'project-team-relationship',
            'In-Reply-To'     => "team-#{@team.path}-project-#{@project.path_with_namespace}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' assignation on '#{@project.path_with_namespace}' project")
  end

  def resigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = JSON.load(@event.data).to_hash
    @project      = Project.find_by_id(@source["project_id"])
    @team         = Team.find_by_id(@source["team_id"])

    if @project && @team
      headers 'X-Gitlab-Entity' => 'team',
              'X-Gitlab-Action' => 'assigned',
              'X-Gitlab-Source' => 'project-team-relationship',
              'In-Reply-To'     => "team-#{@team.path}-project-#{@project.path_with_namespace}"

      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' assignation on '#{@project.path_with_namespace}' project")
    end
  end
end
