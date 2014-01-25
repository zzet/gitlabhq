Sidekiq.configure_server do |config|
  config.redis = {
    url: Gitlab.config.resque.uri,
    namespace: Gitlab.config.resque.namespace
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: Gitlab.config.resque.uri,
    namespace: Gitlab.config.resque.namespace
  }
end
