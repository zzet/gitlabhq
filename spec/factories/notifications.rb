# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification, class: Event::Subscription::Notification do
    event
    subscriber
    subscription
    notification_state "new"
    notified_at nil
  end
end
