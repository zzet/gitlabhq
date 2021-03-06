# == Schema Information
#
# Table name: snippets
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  author_id  :integer          not null
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#  file_name  :string(255)
#  expires_at :datetime
#  private    :boolean          default(TRUE), not null
#  type       :string(255)
#

class Snippet < ActiveRecord::Base
  include Linguist::BlobHelper

  attr_accessible :title, :content, :file_name, :expires_at, :private

  belongs_to :author, class_name: User
  has_many :notes,    as: :noteable,  dependent: :destroy

  default_value_for :private, true

  validates :author, presence: true
  validates :title, presence: true, length: { within: 0..255 }
  validates :file_name, presence: true, length: { within: 0..255 }
  validates :content, presence: true

  # Scopes
  scope :are_public,  -> { where(private: false) }
  scope :are_private, -> { where(private: true) }
  scope :fresh,   -> { order("created_at DESC") }
  scope :expired, -> { where(["expires_at IS NOT NULL AND expires_at < ?", Time.current]) }
  scope :non_expired, -> { where(["expires_at IS NULL OR expires_at > ?", Time.current]) }

  delegate :name, :email, to: :author, prefix: true, allow_nil: true

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
