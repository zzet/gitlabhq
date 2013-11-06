class Emails::Team::TeamProjectRelationship < Emails::Team::Base
  def assigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @tpr          = @event.source
    @team         = @event.target
    @project      = @tpr.project

    headers 'X-Gitlab-Entity' => 'project',
            'X-Gitlab-Action' => 'assigned',
            'X-Gitlab-Source' => 'project-team-relationship',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-team-#{@team.path}"

    mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' was assigned on '#{@project.path_with_namespace}' project")
  end

  def resigned_email(notification)
    @notification = notification
    @event        = @notification.event
    @user         = @event.author
    @source       = JSON.load(@event.data).to_hash
    @project      = Project.find_by_id(@source["project_id"])
    @team         = @event.target

    headers 'X-Gitlab-Entity' => 'team',
            'X-Gitlab-Action' => 'assigned',
            'X-Gitlab-Source' => 'project-team-relationship',
            'In-Reply-To'     => "project-#{@project.path_with_namespace}-team-#{@team.path}"

    if @project
      mail(from: "#{@user.name} <#{@user.email}>", bcc: @notification.subscriber.email, subject: "Team '#{@team.name}' was resigned from '#{@project.path_with_namespace}' project")
    end
  end
end
