# == Schema Information
#
# Table name: event_summary_entity_relationships
#
#  id          :integer          not null, primary key
#  summary_id  :integer
#  entity_id   :integer
#  entity_type :string(255)
#  options     :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_summary_entity_relationship, class: Event::SummaryEntityRelationship do
    summary
    entity { create :project }
  end
end
