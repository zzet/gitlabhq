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

  def can_test?
    false
  end
end
