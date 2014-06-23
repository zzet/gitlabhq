module Repositories::TagsActions
  private

  def create_tag_action(tag, ref)
    project.repository.add_tag(tag, ref)

    if new_tag = project.repository.find_tag(tag)
      oldrev = "0000000000000000000000000000000000000000"
      newrev = new_tag.target
      ref = "refs/tags/" << new_tag.name

      GitPushService.new(current_user, project, oldrev, newrev, ref).execute
    end

    new_tag
  end

  def delete_tag_action(tag)
    tag = project.repository.find_tag(tag)
    if tag && project.repository.rm_tag(tag.name)
      oldrev = tag.target
      newrev = "0000000000000000000000000000000000000000"
      ref = "refs/tags/" << tag.name

      GitPushService.new(current_user, project, oldrev, newrev, ref).execute

      receive_delayed_notifications
    end
  end
end
