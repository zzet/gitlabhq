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
#

class Service::Obs < Service
  default_title       'Obs'
  default_description 'Obs'
  service_name        'obs'

  with_user name: "Obs service", username: "obs_service", email: "example_obs@example.org"

  def can_test?
    false
  end
end
