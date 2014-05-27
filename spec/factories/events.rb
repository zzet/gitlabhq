# == Schema Information
#
# Table name: events
#
#  id                 :integer          not null, primary key
#  author_id          :integer
#  action             :string(255)
#  source_id          :integer
#  source_type        :string(255)
#  target_id          :integer
#  target_type        :string(255)
#  data               :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  parent_event_id    :integer
#  system_action      :string(255)
#  first_domain_id    :integer
#  first_domain_type  :string(255)
#  second_domain_id   :integer
#  second_domain_type :string(255)
#  uniq_hash          :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event, class: Event do
    author
    action Event.action.values.first
    data "MyText"
    source { create :project }
  end

  factory :push_event, class: Event do
    author
    action :pushed
    data { "{\"repository\": \"any\"}" }
    source { create :push }
  end
end
