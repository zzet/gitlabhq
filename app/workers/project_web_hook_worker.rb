class ProjectWebHookWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker

  sidekiq_options queue: :project_web_hook

  def perform(hook_id, data)
    benchmark.execute_webhook do
      WebHook.find(hook_id).execute data
    end
    benchmark.finish
  end
end
