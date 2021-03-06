# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :subscription, class: Event::Subscription do
    user
    action Event.action.values.first
    target factory: :project
    notification_interval 1
    last_notified_at "2013-02-12 16:52:26"
  end

  factory :push_subscription, class: Event::Subscription do
    user
    action :pushed
    target factory: :project
    notification_interval 1
    last_notified_at "2013-02-12 16:52:26"
  end
end
