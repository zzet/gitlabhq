# == Schema Information
#
# Table name: team_group_relationships
#
#  id         :integer          not null, primary key
#  team_id    :integer
#  group_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :team_user_relationship do
    team
    user
    team_access { TeamUserRelationship::MASTER }
  end
end
