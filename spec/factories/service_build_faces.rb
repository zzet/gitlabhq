# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :service_build_face, :class => 'Service::BuildFace' do
    type ""
    title "MyString"
    token "MyString"
    project_id 1
    active false
    project_url "MyString"
  end
end
