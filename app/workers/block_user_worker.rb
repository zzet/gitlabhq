class BlockUserWorker
  include Sidekiq::Worker

  sidekiq_options queue: :common

  def perform(user_idi, author_id)
    author = User.find(author_id)
    user = User.find(user_id)

    RequestStore.store[:current_user] = author

    UsersService.new(author, user).block
  end
end
