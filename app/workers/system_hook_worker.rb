class SystemHookWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker

  sidekiq_options queue: :system_hook

  def perform(hook_id, data)
    benchmark.execute_system_hook do
      SystemHook.find(hook_id).execute data
    end
    benchmark.finish
  end
end
