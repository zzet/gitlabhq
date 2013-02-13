class Event::Action
  # General actions
  CREATED   = 1
  UPDATED   = 2
  COMMENTED = 3
  DELETED   = 4
  ADDED     = 5
  JOINED    = 6
  LEFT      = 7
  TRANSFER  = 8

  # Git specific
  PUSHED    = 9
  CLONED    = 10

  # Issuable
  CLOSED    = 11
  REOPENED  = 12
  MERGED    = 13

  def self.available_actions 
    Action.constants  
  end
end
