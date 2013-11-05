# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :pivotal_tracker_service, class: Service::PivotalTracker do
    type "Service::PivotalTracker"
    title
    description

    after :create do |service|
      service.create_configuration(attributes_for(:pivotal_tracker_configuration))
    end

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

    factory :active_pivotal_tracker_service, traits: [:active]
    factory :public_pivotal_tracker_service, traits: [:public]
    factory :active_enabled_pivotal_tracker_service, traits: [:active, :enabled]
    factory :active_public_pivotal_tracker_service, traits: [:active, :public]
    factory :active_public_enabled_pivotal_tracker_service, traits: [:active, :public, :enabled]
  end
end
