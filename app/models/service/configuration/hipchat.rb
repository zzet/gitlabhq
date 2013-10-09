class Service::Configuration::Hipchat < ActiveRecord::Base
  attr_accessible :room, :token

  belongs_to :service, polymorphic: true

  validates :token, presence: true, if: :enabled?

  delegate :enabled?, to: :service, prefix: false

  def fields
    [
      { type: 'text', name: 'token',     placeholder: '' },
      { type: 'text', name: 'room',      placeholder: '' }
    ]
  end

end
