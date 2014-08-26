class Summaries::WeeklyWorker
  @queue = :mail_notifications

  def self.perform(id)
    summary = Event::Summary.find(id)
    events = summary.events_for current_time
    if events.any?
      current_time = Time.zone.now
      EventSummaryMailer.weekly_digest(summary.user.id,
                                       events.map(&:id),
                                       summary.id,
                                       current_time).deliver!
      summary.last_send_date = current_time
      summary.save
    end
  end
end
