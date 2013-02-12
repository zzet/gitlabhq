# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification do
    event_id 1
    subscription_id 1
    notification_state "MyString"
    notified_at "2013-02-12 16:19:47"
  end
end
