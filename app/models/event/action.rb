class Event::Action
  class << self
    def available_actions
      [
        # General actions
        :all,
        :created,
        :updated,
        :commented,
        :deleted,
        :added,
        :joined,
        :left,
        :transfer,

        # Project specific
        :commented_related,

        # Git specific
        :pushed,
        :cloned,

        # Issuable
        :opened,
        :closed,
        :reopened,
        :merged,
        :assigned,
        :reassigned
      ]
    end

    def action_exists?(action)
      available_actions.include? action
    end
  end
end
