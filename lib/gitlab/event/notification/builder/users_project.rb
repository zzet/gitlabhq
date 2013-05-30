class Gitlab::Event::Notification::Builder::UsersProject < Gitlab::Event::Notification::Builder::Default
  def can_build?(subscription, event)
    return false if team_already_have?(event)

    super
  end

  def team_already_have?(event)
    team_events = ::Event.where(target_id: event.target.id, target_type: event.target.class, created_at: (Time.now - 5.minutes)..Time.now)
    team_events.any?
  end
end
