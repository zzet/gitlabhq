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
