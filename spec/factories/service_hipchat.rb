# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :hipchat_service, class: Service::Hipchat do
    type "Service::Hipchat"
    title
    description

    trait :public do
      public_state "published"
    end

    trait :active do
      active_state "active"
    end

    trait :enabled do
      project
      state "enabled"
    end

    factory :active_hipchat_service, traits: [:active]
    factory :public_hipchat_service, traits: [:public]
    factory :active_enabled_hipchat_service, traits: [:active, :enabled]
    factory :active_public_hipchat_service, traits: [:active, :public]
    factory :active_public_enabled_hipchat_service, traits: [:active, :public, :enabled]
  end
end
