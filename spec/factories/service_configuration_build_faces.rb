# == Schema Information
#
# Table name: service_configuration_build_faces
#
#  id               :integer          not null, primary key
#  service_id       :integer
#  service_type     :string(255)
#  token            :string(255)
#  domain           :string(255)
#  system_hook_path :string(255)
#  web_hook_path    :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :build_face_configuration, class: Service::Configuration::BuildFace do
    service factory: :build_face_service
    domain "http://build-face.undev.cc"
    system_hook_path '/hooks/gitlab'
  end
end
