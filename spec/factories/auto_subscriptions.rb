# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :auto_subscription, class: Event::AutoSubscription do
    user
    target :project

    trait :adjacent do
      namespace_id nil
      namespace_type nil
    end

    factory :adjacent_auto_subscription, traits: [:adjacent]
  end
end
