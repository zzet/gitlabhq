class Service::Configuration::Assembla < ActiveRecord::Base
  attr_accessible :service_id, :service_type, :token

  belongs_to :service, polymorphic: true

  validates :token, presence: true, if: :activated?

  def fields
    [
      { type: 'text', name: 'token', placeholder: '' }
    ]
  end
end
