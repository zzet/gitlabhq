# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :push do
    project_id 1
    ref "MyString"
    before "MyString"
    after "MyString"
    data "MyText"
    user_id 1
    commits_count 1
  end
end
