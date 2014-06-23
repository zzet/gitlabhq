# == Schema Information
#
# Table name: service_configuration_slacks
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
  factory :slack_configuration, class: Service::Configuration::Slack do
    service factory: :slack_service
    token "secret_token"
    subdomain "subdomain"
    room "developers"
  end
end
