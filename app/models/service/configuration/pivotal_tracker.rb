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

class Service::Configuration::PivotalTracker < ActiveRecord::Base
  attr_accessible :token

  belongs_to :service, polymorphic: true

  validates :token, presence: true, if: :enabled?

  delegate :enabled?, to: :service, prefix: false

  def fields
    [
      { type: 'text', name: 'token', placeholder: '' }
    ]
  end
end
