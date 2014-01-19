class TestHookService
  def execute(current_user, hook)
    data = GitPushService.new.sample_data(hook.project, current_user)
    hook.execute(data)
  end
end
