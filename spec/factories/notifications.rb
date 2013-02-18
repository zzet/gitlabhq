# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification, class: Event::Subscription::Notification do
    event
    subscription
    target
    notification_state "new"
    notified_at "2013-02-12 16:19:47"
  end
end
