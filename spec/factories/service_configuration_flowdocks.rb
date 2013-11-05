# == Schema Information
#
# Table name: service_configuration_flowdocks
#
#  id           :integer          not null, primary key
#  service_id   :integer
#  service_type :string(255)
#  token        :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :flowdock_configuration, class: Service::Configuration::Flowdock do
    service factory: :flowdock_service
    token "secret_token"
  end
end
