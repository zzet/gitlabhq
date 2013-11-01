# == Schema Information
#
# Table name: service_configuration_hipchats
#
#  id           :integer          not null, primary key
#  service_id   :integer
#  service_type :string(255)
#  token        :string(255)
#  room         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :hipchat_configuration, class: Service::Configuration::Hipchat do
    service factory: :hipchat_service
    token "secret_token"
    room "developers"
  end
end
