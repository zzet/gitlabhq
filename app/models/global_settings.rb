# == Schema Information
#
# Table name: global_settings
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#

class GlobalSettings < ActiveRecord::Base

  has_many :email_domains, class_name: GlobalSettings::EmailDomains

  class << self
    def allowed_email_domains
      GlobalSettings::EmailDomains.pluck(:domain)
    end
  end
end
