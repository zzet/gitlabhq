require 'resque-scheduler'

# Custom Redis configuration
config_file = Rails.root.join('config', 'resque.yml')

resque_url = if File.exists?(config_file)
               YAML.load_file(config_file)[Rails.env]
             else
               "redis://localhost:6379"
             end

Resque.redis = resque_url
Resque.redis.namespace = "resque:gitlab"

Resque::Scheduler.dynamic = true
