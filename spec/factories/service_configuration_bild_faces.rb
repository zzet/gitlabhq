# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :service_configuration_bild_face, :class => 'Service::Configuration::BildFace' do
    service_id 1
    token "MyString"
    domain "MyString"
    system_hook_path "MyString"
  end
end
