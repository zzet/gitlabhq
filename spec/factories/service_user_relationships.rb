# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :service_user_relationship do
    service
    user
  end
end
