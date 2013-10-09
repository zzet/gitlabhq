# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :campfire_service, class: Service::Campfire do
    type "Service::Campfire"
    title
    description

    after :create do |service|
      service.create_configuration(attributes_for(:campfire_configuration))
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

    factory :active_campfire_service, traits: [:active]
    factory :public_campfire_service, traits: [:public]
    factory :active_enabled_campfire_service, traits: [:active, :enabled]
    factory :active_public_campfire_service, traits: [:active, :public]
    factory :active_public_enabled_campfire_service, traits: [:active, :public, :enabled]
  end
end
