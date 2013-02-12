# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_basis, :class => 'Event::Base' do
    user
    action "Action"
    target_id 1
    target_type "MyString"
    data "MyText"
  end
end
