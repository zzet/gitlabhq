# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ci_build do
    target_project factory: :project
    source_project factory: :project
    merge_request factory: :merge_request
    user
    source_sha "MyString"
    target_sha "MyString"
    state "build"
    trace "MyText"
    coverage "MyText"
  end
end
