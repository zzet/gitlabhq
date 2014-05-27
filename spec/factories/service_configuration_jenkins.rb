# == Schema Information
#
# Table name: service_configuration_jenkins
#
#  id                    :integer          not null, primary key
#  service_id            :integer
#  service_type          :string(255)
#  host                  :string(255)
#  push_path             :string(255)
#  merge_request_path    :string(255)
#  branches              :text
#  merge_request_enabled :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :jenkins_configuration, class: Service::Configuration::Jenkins do
    host "http://ci.example.com"
    push_path "/build/project"
    merge_request_path "/build/merge_request"
    branches "develop, master, staging"
    merge_request_enabled false
  end
end
