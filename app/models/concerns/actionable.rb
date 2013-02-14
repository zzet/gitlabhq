module Actionable
  extend ActiveSupport::Concern

  included do
    extend Enumerize

    enumerize :action, :in => Event::Action.available_actions

    validates :action, presence: true
  end
end
