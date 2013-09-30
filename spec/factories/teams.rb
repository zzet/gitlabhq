# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :team do
    name
    description
    sequence(:path) { |n| "team-path-#{n}"}
    public true
  end
end
