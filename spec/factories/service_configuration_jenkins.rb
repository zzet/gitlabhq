# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :jenkin_configuration, class: Service::Configuration::Jenkins do
    host "http://ci.example.com"
    push_path "/build/project"
    merge_request_path "/build/merge_request"
    branches "develop, master, staging"
    merge_request_enabled false
  end
end
