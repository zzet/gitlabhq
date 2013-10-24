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

class Service::Nix < Service
  default_title       'Nix'
  default_description 'Nix'
  service_name        'nix'

  with_user name: "Nix service", username: "nix_service", email: "example_nix@example.org"
end
