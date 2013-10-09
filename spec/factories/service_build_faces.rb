# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :build_face_service, class: Service::BuildFace do
    type "Service::BuildFace"
    title
    description
    project

    trait :public do
      public_state "published"
    end

    trait :active do
      active_state "active"
    end

    trait :enabled do
      state "enabled"
    end

    factory :active_build_face_service, traits: [:active]
    factory :public_build_face_service, traits: [:public]
    factory :active_enabled_build_face_service, traits: [:active, :enabled]
    factory :active_public_build_face_service, traits: [:active, :public]
    factory :active_public_enabled_build_face_service, traits: [:active, :public, :enabled]
  end
end
