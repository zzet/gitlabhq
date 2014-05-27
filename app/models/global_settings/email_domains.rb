# == Schema Information
#
# Table name: global_setting_email_domains
#
#  id                 :integer          not null, primary key
#  global_settings_id :integer
#  domain             :string(255)
#  description        :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#

class GlobalSettings::EmailDomains < ActiveRecord::Base
  attr_accessible :domain, :description

  belongs_to :global_settings

  validates :domain,      presence: true, uniqueness: true
  validates :description, presence: true
end
