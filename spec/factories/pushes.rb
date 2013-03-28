# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :push do
    project
    ref "refs/heads/master"
    before "old_rev"
    after "new_rev"
    data "{ push_data_hash: \"value\"}"
    user
    commits_count 1
  end
end
