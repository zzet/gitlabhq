class GlobalSettings < ActiveRecord::Base

  has_many :email_domains, class_name: GlobalSettings::EmailDomains

  class << self
    def allowed_email_domains
      GlobalSettings::EmailDomains.pluck(:domain)
    end
  end
end
