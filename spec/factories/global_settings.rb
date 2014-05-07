# == Schema Information
#
# Table name: global_settings
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :global_setting, :class => 'GlobalSettings' do
  end
end
