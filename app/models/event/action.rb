class Event::Action
  # General actions
  CREATED    = 1
  UPDATED    = 2
  COMMENTED  = 3
  DELETED    = 4
  ADDED      = 5
  JOINED     = 6
  LEFT       = 7
  TRANSFER   = 8

  # Git specific
  PUSHED     = 9
  CLONED     = 10

  # Issuable
  CLOSED     = 11
  REOPENED   = 12
  MERGED     = 13
  ASSIGNED   = 14
  REASSIGNED = 15

  class << self
    def available_actions
      constants
    end

    def action_to_s(action)
      const = constants.find { |name| const_get(name) == action }
      const.to_s.downcase!
    end

    def action_by_name(action)
      constants.find { |name| name.to_sym == action }
    end
  end
end
