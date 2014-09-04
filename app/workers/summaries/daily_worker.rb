class Summaries::DailyWorker
  @queue = :mail_notifications

  def self.perform
    Event::Summary.current_daily.find_each do |summary|
      current_time = Time.zone.now

      events = summary.events_for(current_time)
      if events.any?

        EventSummaryMailer.daily_digest(summary.user.id,
                                        events.map(&:id),
                                        summary.id,
                                        current_time).deliver!

        summary.last_send_date = current_time
        summary.save
      end
    end
  end
end
