class TestHookService
  def execute(current_user, hook)
    data = GitPushService.new.sample_data(current_user, hook.project)
    hook.execute(data)
  end
end
