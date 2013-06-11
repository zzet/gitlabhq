class UserObserver < BaseObserver
  def after_create(user)
    log_info("User \"#{user.name}\" (#{user.email}) was created")
  end

  def after_destroy user
    log_info("User \"#{user.name}\" (#{user.email})  was removed")
  end

  def after_save user
    # Ensure user has namespace
    user.create_namespace!(path: user.username, name: user.username) unless user.namespace

    if user.username_changed? || user.name_changed?
      user.namespace.update_attributes(path: user.username, name: user.name)
    end
  end
end
