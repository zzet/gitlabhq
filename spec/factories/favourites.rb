# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :favourite do
    user
    entity factory: :project
  end
end
