class BlockUserWorker
  @queue = :common

  def self.perform(user_id, author_id)
    author = User.find(author_id)
    user = User.find(user_id)

    RequestStore.store[:current_user] = author

    UsersService.new(author, user).block
  end
end
