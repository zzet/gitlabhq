# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :redmine_service, class: Service::Redmine do
    type "Service::Redmine"
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

    factory :active_redmine_service, traits: [:active]
    factory :public_redmine_service, traits: [:public]
    factory :active_enabled_redmine_service, traits: [:active, :enabled]
    factory :active_public_redmine_service, traits: [:active, :public]
    factory :active_public_enabled_redmine_service, traits: [:active, :public, :enabled]
  end
end
