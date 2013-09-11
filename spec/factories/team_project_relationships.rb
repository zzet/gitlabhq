# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :team_project_relationship do
    team
    project
  end
end
