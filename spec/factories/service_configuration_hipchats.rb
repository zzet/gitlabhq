# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :hipchat_configuration, class: Service::Configuration::Hipchat do
    token "secret_token"
    room "developers"
  end
end
