# == Schema Information
#
# Table name: teams
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  path        :string(255)
#  description :text
#  creator_id  :integer
#  public      :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :team do
    creator factory: :user
    sequence(:name) { |n| "team#{n}" }
    description
    sequence(:path) { |n| "team-path-#{n}"}
    public true
  end
end
