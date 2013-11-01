# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :flowdock_configuration, class: Service::Configuration::Flowdock do
    service factory: :flowdock_service
    token "secret_token"
  end
end
