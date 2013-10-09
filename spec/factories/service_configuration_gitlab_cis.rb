# == Schema Information
#
# Table name: service_configuration_gitlab_cis
#
#  id           :integer          not null, primary key
#  service_id   :integer
#  service_type :string(255)
#  token        :string(255)
#  project_url  :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :gitlab_ci_configuration, class: Service::Configuration::GitlabCi do
    token "verySecret"
    project_url "http://ci.gitlab.org/projects/2"
  end
end
