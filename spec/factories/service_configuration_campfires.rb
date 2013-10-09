# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :campfire_configuration, class: Service::Configuration::Campfire do
    subdomain "gitlab1"
    token 'secret_token'
    room 'developers'
  end
end
