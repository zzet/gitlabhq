# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :subscription_option, class: Event::SubscriptionOption do
    subscription
    source :project
  end
end
