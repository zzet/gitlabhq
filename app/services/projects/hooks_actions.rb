module Projects::HooksActions
  private

  def remove_hook_action(hook)
    hook.destroy
    receive_delayed_notifications
  end

  def test_hook_action(hook)
    data = Projects::PushService.new.sample_data(current_user, project)
    hook.execute(data)
  end
end
