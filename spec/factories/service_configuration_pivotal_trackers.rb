# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :pivotal_tracker_configuration, class: Service::Configuration::PivotalTracker do
    service factory: :pivotal_tracker_service
    token "secret_token"
  end
end
