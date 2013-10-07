# == Schema Information
#
# Table name: team_project_relationships
#
#  id         :integer          not null, primary key
#  project_id :integer
#  team_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :team_project_relationship do
    team
    project
  end
end
