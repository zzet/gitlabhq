class Banner < ActiveRecord::Base
  extend Enumerize

  attr_accessible :author_id, :category, :description, :end_date, :entity_id, :entity_type, :start_date, :state, :state_event, :title

  belongs_to :author, class_name: User
  belongs_to :entity, polymorphic: true

  def self.available_categories
    %w(alert-block alert-error alert-success alert-info)
  end

  enumerize :category, in: Banner.available_categories, scope: :by_category

  validates :author, presence: true
  validates :category, presence: true
  validates :title, presence: true
  validates :description, presence: true

  scope :published, -> { where(state: :published) }

  state_machine :state, initial: :draft do
    event :to_draft do
      transition [:published, :unpublished] => :draft
    end

    event :publish do
      transition [:draft, :unpublished] => :published
    end

    event :unpublish do
      transition :published => :unpublished
    end

    state :published

    state :unpublished

    state :draft
  end

  def available_categories
    self.class.available_categories - category
  end

end
