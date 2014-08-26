$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'
require 'resque/tasks'

task 'resque:setup' => :environment

namespace :resque do
  task :setup do
    require 'resque'
    require 'resque-scheduler'

    Resque::Scheduler.dynamic = true

    # Load static schedule (only in background servers).
    # The schedule doesn't need to be stored in a YAML, it just needs to
    # be a hash.  YAML is usually the easiest.
    Resque.schedule = YAML.load_file(
      File.join(Rails.root.to_s, 'config', 'gitlab_job_schedule.yml')
    )

    Resque.before_fork do |job|
      ActiveRecord::Base.establish_connection
    end
  end
end
