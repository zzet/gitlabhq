# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :nix_service, class: Service::Nix do
    type "Service::Nix"
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

    factory :active_nix_service, traits: [:active]
    factory :public_nix_service, traits: [:public]
    factory :active_enabled_nix_service, traits: [:active, :enabled]
    factory :active_public_nix_service, traits: [:active, :public]
    factory :active_public_enabled_nix_service, traits: [:active, :public, :enabled]
  end
end
