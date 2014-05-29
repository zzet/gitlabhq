# == Schema Information
#
# Table name: ci_builds
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  target_project_id :integer
#  source_project_id :integer
#  merge_request_id  :integer
#  service_id        :integer
#  service_type      :string(255)
#  source_branch     :string(255)
#  target_branch     :string(255)
#  source_sha        :string(255)
#  target_sha        :string(255)
#  state             :string(255)
#  trace             :text
#  coverage          :text
#  data              :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  build_time        :datetime
#  duration          :time
#  skipped_count     :integer          default(0)
#  failed_count      :integer          default(0)
#  total_count       :integer          default(0)
#

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
