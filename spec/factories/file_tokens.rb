# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :file_token do
    user
    project
    token { Digest::MD5.hexdigest(Time.now.to_s) }
    file "MyString"
    last_usage_at "2013-04-09 10:49:24"
    usage_count 1
  end
end
