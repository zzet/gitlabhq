# == Schema Information
#
# Table name: file_tokens
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  project_id    :integer
#  token         :string(255)
#  file          :string(255)
#  last_usage_at :datetime
#  usage_count   :integer          default(0)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  source_ref    :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :file_token do
    user
    project factory: :project
    source_ref "master"
    token { Digest::MD5.hexdigest(Time.now.to_s) }
    file "MyString"
    last_usage_at "2013-04-09 10:49:24"
    usage_count 1
  end
end
