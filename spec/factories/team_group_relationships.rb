# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :team_group_relationship do
    team
    group
  end
end
