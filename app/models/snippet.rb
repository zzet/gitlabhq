# == Schema Information
#
# Table name: snippets
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  author_id  :integer          not null
#  project_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  file_name  :string(255)
#  expires_at :datetime
#

class Snippet < ActiveRecord::Base
  include Watchable
  include Linguist::BlobHelper

  attr_accessible :title, :content, :file_name, :expires_at

  belongs_to :project
  belongs_to :author, class_name: User
  has_many :notes,    as: :noteable,  dependent: :destroy

  has_many :events,         as: :source
  has_many :subscriptions,  as: :target, dependent: :destroy, class_name: Event::Subscription
  has_many :notifications,  through: :subscriptions
  has_many :subscribers,    through: :subscriptions

  delegate :name, :email, to: :author, prefix: true, allow_nil: true

  validates :author, presence: true
  validates :project, presence: true
  validates :title, presence: true, length: { within: 0..255 }
  validates :file_name, presence: true, length: { within: 0..255 }
  validates :content, presence: true

  # Scopes
  scope :fresh, -> { order("created_at DESC") }
  scope :non_expired, -> { where(["expires_at IS NULL OR expires_at > ?", Time.current]) }
  scope :expired, -> { where(["expires_at IS NOT NULL AND expires_at < ?", Time.current]) }

  actions_to_watch [:created, :updated, :deleted]

  def self.content_types
    [
      ".rb", ".py", ".pl", ".scala", ".c", ".cpp", ".java",
      ".haml", ".html", ".sass", ".scss", ".xml", ".php", ".erb",
      ".js", ".sh", ".coffee", ".yml", ".md"
    ]
  end

  def data
    content
  end

  def size
    0
  end

  def name
    file_name
  end

  def mode
    nil
  end

  def expired?
    expires_at && expires_at < Time.current
  end
end
