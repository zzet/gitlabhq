# == Schema Information
#
# Table name: service_user_relationships
#
#  id         :integer          not null, primary key
#  service_id :integer
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :service_user_relationship do
    service
    user
  end
end
