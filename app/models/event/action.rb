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
        :created_branch,
        :deleted_branch,
        :created_tag,
        :deleted_tag,
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
      action = action.to_sym if action.is_a? String
      available_actions.include? action
    end
  end
end
