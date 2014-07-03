# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :redmine_configuration, class: Service::Configuration::Redmine do
    domain "http://pm.undev.cc"
    web_hook_path "/hooks"
    service factory: :redmine_service
  end
end
