# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :gitlab_ci_configuration, class: Service::Configuration::GitlabCi do
    token "verySecret"
    project_url "http://ci.gitlab.org/projects/2"
  end
end
