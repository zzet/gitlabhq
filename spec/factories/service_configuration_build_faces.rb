# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :bild_face_configuration, class: Service::Configuration::BuildFace do
    service { create :build_face_service }
    domain "http://build-face.undev.cc"
    system_hook_path '/hooks/gitlab'
  end
end
