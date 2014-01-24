class Gitlab::Event::Notification::Creator::User::UserBlocked < Gitlab::Event::Notification::Creator::Default
  def create(event)
    user = event.target
    notifications = []

    # Subscriptions on User
    subscriptions = ::Event::Subscription.by_target(user).by_source_type(event.source_type)
    notifications << create_by_subscriptions(event, subscriptions, :delayed)

    data = JSON.load(event.data)

    # Subscriptions on Teams
    teams = data["teams"]
    teams.each do |team|
      team = Team.find_by(id: team["id"])
      if team.present?
        subscriptions = ::Event::Subscription.by_target(team).by_source_type(event.source_type)
        notifications << create_by_subscriptions(event, subscriptions, :delayed)
      end
    end

    # Gorup subscriptions
    groups = data["groups"]
    groups.each do |group|
      group = Group.find_by(id: group["id"])
      if group.present?
        subscriptions = ::Event::Subscription.by_target(group).by_source_type(event.source_type)
        notifications << create_by_subscriptions(event, subscriptions, :delayed)
      end
    end

    # Subscription on Projects
    projects = data["projects"]
    projects.each do |project|
      project = Project.find_by(id: project["id"])
      if project.present?
        subscriptions = ::Event::Subscription.by_target(project).by_source_type(event.source_type)
        notifications << create_by_subscriptions(event, subscriptions, :delayed)
      end
    end

    notifications
  end
end
