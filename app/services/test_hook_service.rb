class TestHookService
  def execute(current_user, hook)
    data = GitPushService.new(current_user, hook.project).sample_data
    hook.execute(data)
  end
end
