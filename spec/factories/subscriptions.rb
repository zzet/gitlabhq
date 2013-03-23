# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :subscription, class: Event::Subscription do
    user
    action Event.action.values.first
    target
    source
    notification_interval nil
    last_notified_at nil
  end
end
