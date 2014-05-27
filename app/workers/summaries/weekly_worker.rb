class Summaries::WeeklyWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options queue: :mail_notifications

  recurrence { daily }

  def perform
    summaries = Event::Summary.current_weekly
    summaries.each do |summary|
      current_time = Time.zone.now

      events = summary.events_for current_time
      next if events.blank?

      EventSummaryMailer.weekly_digest(summary.user.id, events.map(&:id), summary.id, current_time).deliver!

      summary.last_send_date = current_time
      summary.save
    end
  end
end
