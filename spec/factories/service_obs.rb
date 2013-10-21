# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :obs_service, class: Service::Obs do
    type "Service::Obs"
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

    factory :active_obs_service, traits: [:active]
    factory :public_obs_service, traits: [:public]
    factory :active_enabled_obs_service, traits: [:active, :enabled]
    factory :active_public_obs_service, traits: [:active, :public]
    factory :active_public_enabled_obs_service, traits: [:active, :public, :enabled]
  end
end
