# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :assembla_service, class: Service::Assembla do
    type "Service::Assembla"
    title
    description

    after :create do |service|
      service.create_configuration(attributes_for(:assembla_configuration))
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

    factory :active_assembla_service, traits: [:active]
    factory :public_assembla_service, traits: [:public]
    factory :active_enabled_assembla_service, traits: [:active, :enabled]
    factory :active_public_assembla_service, traits: [:active, :public]
    factory :active_public_enabled_assembla_service, traits: [:active, :public, :enabled]
  end
end
