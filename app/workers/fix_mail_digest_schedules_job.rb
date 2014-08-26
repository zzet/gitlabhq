# vim:fileencoding=utf-8
#
# Background job to fix the schedule for email sending. Any missing
# schedule will be added to resque-schedule.
#
# Recent resque-scheduler versions wipe all dynamic schedules when
# restarting. This means all dynamic schedules, which are added via the
# API, are wiped on each application redeployment. A workaround for this
# sometimes undesirable behavior is to make this job part of a static
# schedule (see config/initializers/resque.rb and
# config/static_schedule.yml).  This job will be scheduled to run every
# hour even after restarting resque-schedule, and will add back the
# dynamic schedules that were wiped on restart. It also serves as
# safeguard against schedules getting lost for any reason.
#
# For more detail about this unfortunate behavior of resque-scheduler see:
#
#   https://github.com/resque/resque-scheduler/issues/269
#
# The perform method of this class will be invoked from a Resque worker.
class FixMailDigestSchedulesJob
  @queue = :mail_notifications

  # Fix email sending schedules. Any digests which does not have scheduled
  # sending of emails will be detected, and the missing scheduled job
  # will be added to resque-schedule.
  #
  # This method is intended to be invoked from Resque, which means it is
  # performed in the background.
  class << self
    def perform
      daily_digests
      weekly_digests
      monthly_digests
    end

    def daily_digests
      unscheduled_digests = []
      Event::Summary.current_daily.find_each do |summary|
        schedule = Resque.fetch_schedule("events_digest_#{summary.id}")
        unscheduled_digests << summary if schedule.nil?
      end

      if unscheduled_digests.length > 0
        unscheduled_digests.each do |digest|
          name = "send_email_#{digest.id}"
          config = {}
          config[:class] = 'Summaries::DailyWorker'
          config[:args] = digest.id
          config[:every] = '1d'
          Resque.set_schedule(name, config)
        end
      end
    end

    def weekly_digests
      unscheduled_digests = []
      Event::Summary.current_weekly.find_each do |summary|
        schedule = Resque.fetch_schedule("events_digest_#{summary.id}")
        unscheduled_digests << summary if schedule.nil?
      end

      if unscheduled_digests.length > 0
        unscheduled_digests.each do |digest|
          name = "send_email_#{digest.id}"
          config = {}
          config[:class] = 'Summaries::WeeklyWorker'
          config[:args] = digest.id
          config[:every] = '1w'
          Resque.set_schedule(name, config)
        end
      end
    end

    def monthly_digests
      unscheduled_digests = []
      Event::Summary.current_monthly.find_each do |summary|
        schedule = Resque.fetch_schedule("events_digest_#{summary.id}")
        unscheduled_digests << summary if schedule.nil?
      end

      if unscheduled_digests.length > 0
        unscheduled_digests.each do |digest|
          name = "send_email_#{digest.id}"
          config = {}
          config[:class] = 'Summaries::MonthlyWorker'
          config[:args] = digest.id
          config[:cron] = '00 23 L * *'
          Resque.set_schedule(name, config)
        end
      end
    end
  end
end
