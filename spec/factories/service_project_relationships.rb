# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :service_project_relationship do
    project_id 1
    service_id 1
    service_type 1
  end
end
