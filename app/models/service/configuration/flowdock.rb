class Service::Configuration::Flowdock < ActiveRecord::Base
  attr_accessible :token

  belongs_to :service, polymorphic: true

  validates :token, presence: true, if: :enabled?

  delegate :enabled?, to: :service, prefix: false

  def fields
    [
      { type: 'text', name: 'token',     placeholder: '' }
    ]
  end
end
