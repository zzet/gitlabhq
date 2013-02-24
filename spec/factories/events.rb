# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event, :class => 'Event' do
    author
    action Event.action.values.first
    data "MyText"
    source_id 1
    source_type "Issue"
  end
end
