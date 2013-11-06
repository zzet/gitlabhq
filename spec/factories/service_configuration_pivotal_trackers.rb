# == Schema Information
#
# Table name: service_configuration_pivotal_trackers
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
  factory :pivotal_tracker_configuration, class: Service::Configuration::PivotalTracker do
    service factory: :pivotal_tracker_service
    token "secret_token"
  end
end
