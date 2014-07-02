module Favouriteable
  extend ActiveSupport::Concern

  included do
    has_many :favourites, as: :entity, dependent: :destroy
    has_many :followers,  through: :favourites, foreign_key: :user_id, class_name: User
  end

  def favourited_by?(user)
    user.personal_favourites.find_by(entity_id: self.id, entity_type: self.class.name).present?
  end
end
