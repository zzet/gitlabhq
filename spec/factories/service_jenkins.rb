# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :jenkins_service, class: Service::Jenkins do
    type "Service::Jenkins"
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

    factory :active_jenkins_service, traits: [:active]
    factory :public_jenkins_service, traits: [:public]
    factory :active_enabled_jenkins_service, traits: [:active, :enabled]
    factory :active_public_jenkins_service, traits: [:active, :public]
    factory :active_public_enabled_jenkins_service, traits: [:active, :public, :enabled]
  end
end
