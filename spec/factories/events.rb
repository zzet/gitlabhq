# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event, :class => 'Event' do
    author
    action Event.action.values.first
    data "MyText"
    source { create :project }
  end

  factory :push_event, :class => 'Event' do
    author
    action :pushed
    data { "{\"repository\": \"any\"}" }
    source_id nil
    source_type "Push_summary"
  end

  factory :created_group_group_event, :class => 'Event' do
    author
    action :created
    data "MyText"
    source { Group.create }
  end
end
