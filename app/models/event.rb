class Event::Base < ActiveRecord::Base
  attr_accessible :action, :data, :target_id, :target_type, :author_id

  belongs_to :author
  belongs_to :target, polymorphic: true

  validates :author,  presence: true
  validates :target,  presence: true
end
