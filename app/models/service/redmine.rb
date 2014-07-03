# == Schema Information
#
# Table name: services
#
#  id                 :integer          not null, primary key
#  type               :string(255)
#  title              :string(255)
#  project_id         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  state              :string(255)
#  service_pattern_id :integer
#  public_state       :string(255)
#  active_state       :string(255)
#  description        :text
#  recipients         :text
#  api_key            :string(255)
#

class Service::Redmine < Service
  default_title       'Redmine'
  default_description 'Redmine'
  service_name        'redmine'

  has_one :configuration, as: :service, class_name: Service::Configuration::Redmine

  def execute(data)
    compose_service_hook unless service_hook.present?

    service_hook.async_execute(data) if service_hook.present?
  end

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = "#{configuration.domain}/#{configuration.web_hook_path}"
    hook.save
  end

  def can_test?
    false
  end
end
