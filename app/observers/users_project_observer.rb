class UsersProjectObserver < ActiveRecord::Observer
  def after_commit(users_project)
    return if users_project.destroyed?
  end

  def after_create(users_project)
    OldEvent.create(
      project_id: users_project.project.id,
      action: OldEvent::JOINED,
      author_id: users_project.user.id
    )
  end

  def after_destroy(users_project)
    OldEvent.create(
      project_id: users_project.project.id,
      action: OldEvent::LEFT,
      author_id: users_project.user.id
    )
  end
end
