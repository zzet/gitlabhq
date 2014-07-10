# == Schema Information
#
# Table name: events
#
#  id              :integer          not null, primary key
#  author_id       :integer
#  action          :string(255)
#  source_id       :integer
#  source_type     :string(255)
#  target_id       :integer
#  target_type     :string(255)
#  data            :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  parent_event_id :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :push, class: Push do
    user
    project   factory: :project
    revbefore "b98a310def241a6fd9c9a9a3e7934c48e498fe81"
    revafter  "b19a04f53caeebf4fe5ec2327cb83e9253dc91bb"
    ref       "refs/heads/master"
  end
end
