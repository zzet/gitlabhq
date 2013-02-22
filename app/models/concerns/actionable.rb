module Actionable
  extend ActiveSupport::Concern

  included do
    extend Enumerize

    enumerize :action, :in => Event::Action.available_actions, scope: :by_action

    validates :action, presence: true
  end
end
