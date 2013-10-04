# == Schema Information
#
# Table name: event_subscription_notification_settings
#
#  id                     :integer          not null, primary key
#  user_id                :integer
#  own_changes            :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  adjacent_changes       :boolean
#  brave                  :boolean
#  subscribe_if_owner     :boolean
#  subscribe_if_developer :boolean
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_subscription_notification_setting, :class => 'Event::Subscription::NotificationSetting' do
    user
    own_changes false
  end
end
