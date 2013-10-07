# == Notifiable concern
#
# Contains notification functionality shared between UsersProject and UsersGroup
#
module Notifiable
  extend ActiveSupport::Concern

  included do
    validates :notification_level, presence: true
  end

  def notification
  end
end
