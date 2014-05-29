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

require 'spec_helper'

describe GlobalSettings::EmailDomains do
  pending "add some examples to (or delete) #{__FILE__}"
end
