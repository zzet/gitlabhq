# == Schema Information
#
# Table name: service_configuration_gemnasia
#
#  id           :integer          not null, primary key
#  token        :string(255)
#  api_key      :string(255)
#  service_id   :integer
#  service_type :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#

class Service::Configuration::Gemnasium < ActiveRecord::Base
  attr_accessible :service_id, :service_type, :token, :api_key

  belongs_to :service, polymorphic: true

  validates :token, :api_key, presence: true, if: :enabled?

  delegate :enabled?, to: :service, prefix: false

  def fields
    [
      { type: 'text', name: 'api_key', placeholder: 'Your personal API KEY on gemnasium.com ' },
      { type: 'text', name: 'token',   placeholder: 'The project\'s slug on gemnasium.com' }
    ]
  end
end
