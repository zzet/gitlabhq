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

class Service::Configuration::Slack < ActiveRecord::Base
  attr_accessible :room, :subdomain, :token

  belongs_to :service, polymorphic: true

  validates :subdomain, presence: true, if: :enabled?
  validates :room,      presence: true, if: :enabled?
  validates :token,     presence: true, if: :enabled?

  delegate :enabled?, to: :service, prefix: false

  def fields
    [
      { type: 'text', name: 'subdomain', placeholder: '' },
      { type: 'text', name: 'token',     placeholder: '' },
      { type: 'text', name: 'room',      placeholder: 'Ex. #general' },
    ]
  end

end
