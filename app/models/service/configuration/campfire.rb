class Service::Configuration::Campfire < ActiveRecord::Base
  attr_accessible :room, :subdomain, :token

  belongs_to :service, polymorphic: true

  validates :token, presence: true, if: :enabled?

  delegate :enabled?, to: :service, prefix: false

  def fields
    [
      { type: 'text', name: 'token',     placeholder: '' },
      { type: 'text', name: 'subdomain', placeholder: '' },
      { type: 'text', name: 'room',      placeholder: '' }
    ]
  end

end
