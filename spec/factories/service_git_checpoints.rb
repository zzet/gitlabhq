# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :git_checkpoint_service, class: Service::GitCheckpoint do
    type "Service::GitCheckpoint"
    title
    description

    after :create do |service|
      service.create_configuration(attributes_for(:git_checkpoint_configuration))
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

    factory :active_git_checkpoint_service, traits: [:active]
    factory :public_git_checkpoint_service, traits: [:public]
    factory :active_enabled_git_checkpoint_service, traits: [:active, :enabled]
    factory :active_public_git_checkpoint_service, traits: [:active, :public]
    factory :active_public_enabled_git_checkpoint_service, traits: [:active, :public, :enabled]
  end
end
