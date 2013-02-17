# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event, :class => 'Event' do
    author
    action "Action"
    target_id 1
    target_type "MyString"
    data "MyText"
  end
end
