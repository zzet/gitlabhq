# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ci_build do
    target_project_id 1
    source_project_id 1
    merge_request_id 1
    source_sha "MyString"
    target_sha "MyString"
    state "MyString"
    trace "MyText"
    coverage "MyText"
  end
end
