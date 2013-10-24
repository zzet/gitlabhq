# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :deploy_key_service_relationship do
    deploy_key_id 1
    service_id 1
  end
end
