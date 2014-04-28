class GlobalSettings::EmailDomains < ActiveRecord::Base
  attr_accessible :domain, :description

  belongs_to :global_settings

  validates :domain,      presence: true, uniqueness: true
  validates :description, presence: true
end
