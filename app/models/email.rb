# == Schema Information
#
# Table name: emails
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  email      :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#

class Email < ActiveRecord::Base
  attr_accessible :email, :user_id

  #
  # Relations
  #
  belongs_to :user

  #
  # Validations
  #
  validates :user_id, presence: true
  validates :email, presence: true, email: { strict_mode: true }, uniqueness: true
  validate :unique_email, if: ->(email) { email.email_changed? }

  before_validation :cleanup_email

  def cleanup_email
    self.email = self.email.downcase.strip
  end

  def unique_email
    if User.exists?(email: self.email)
      self.errors.add(:email, 'has already been taken')
    end
  end
end
