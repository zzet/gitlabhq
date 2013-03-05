# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_subscription_notification_setting, :class => 'Event::Subscription::NotificationSetting' do
    user
    notifyown_changes false
  end
end
