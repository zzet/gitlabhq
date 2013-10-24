# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :gitlab_ci_service, class: Service::GitlabCi do
    type "Service::GitlabCi"
    title
    description

    after :create do |service|
      service.create_configuration(attributes_for(:gitlab_ci_configuration))
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

    factory :active_gitlab_ci_service, traits: [:active]
    factory :public_gitlab_ci_service, traits: [:public]
    factory :active_enabled_gitlab_ci_service, traits: [:active, :enabled]
    factory :active_public_gitlab_ci_service, traits: [:active, :public]
    factory :active_public_enabled_gitlab_ci_service, traits: [:active, :public, :enabled]
  end
end
