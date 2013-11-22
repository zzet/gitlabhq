# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ci_build do
    target_project factory: :project
    source_project factory: :project
    service        factory: :jenkins_service
    merge_request  factory: :merge_request
    user           factory: :user
    source_branch "develop"
    target_branch "master"
    source_sha "MyString"
    target_sha "MyString"
    state      "build"
    trace      "MyText"
    coverage   "MyText"
  end
end
