class Event::Action
  # General actions
  ALL               = 0
  CREATED           = 1
  UPDATED           = 2
  COMMENTED         = 3
  DELETED           = 4
  ADDED             = 5
  JOINED            = 6
  LEFT              = 7
  TRANSFER          = 8

  # Project specific
  COMMENTED_RELATED = 9

  # Git specific
  PUSHED            = 10
  CLONED            = 11

  # Issuable
  OPENED            = 12
  CLOSED            = 13
  REOPENED          = 14
  MERGED            = 15
  ASSIGNED          = 16
  REASSIGNED        = 17

  class << self
    def available_actions
      constants.map {|const| const_get(const)}
    end

    def action_to_s(action)
      const = constants.find { |name| const_get(name) == action }
      const.to_s.downcase!
    end

    def action_to_sym(action)
      action_to_s.to_sym
    end

    def action_by_name(action)
      const = constants.find { |name| name.downcase == action }
      const_get(const).to_i
    end
  end
end
