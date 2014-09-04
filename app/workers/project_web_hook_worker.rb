class ProjectWebHookWorker
  @queue = :project_web_hook

  def self.perform(hook_id, data)
    WebHook.find(hook_id).execute data
  end
end
