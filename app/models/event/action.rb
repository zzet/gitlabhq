class Event::Action
  GENERAL = [
    :all, # NOTE WTF???
    :created,
    :updated,
    :commented,
    :deleted,
    :added,
    :removed,
    :joined,
    :left,
    :transfer,
  ]

  COMMENTS = [
    :commented_merge_request,
    :commented_issue, # not used
    :commented_commit,
    :commented, # not used
  ]

  MERGE_REQUESTS = [
    :opened,
    :closed,
    :reopened, # NOTE doesn't work yet
    :merged,
    :assigned, # NOTE doesn't shown anywhere
    :reassigned, # NOTE doesn't shown anywhere
    :resigned, # NOTE doesn't shown anywhere
  ]

  MASS = [
    :imported,
    :members_added,
    :members_updated,
    :members_removed,
    :teams_added,
    :teams_removed,
    :groups_added,
    :projects_added
  ]

  GIT = [
    :pushed,
    :created_branch,
    :deleted_branch,
    :created_tag,
    :deleted_tag,
    :protected,
    :unprotected,
    :cloned, # NOTE I don't know what is it
    :blocked, # TODO
    :activate, # TODO
  ]

  # NOTE actions which can be parent
  BASE = [
      :create,
      :update,
      :delete,
      :open,
      :close,
      :reopen,
      :merge,
      :block,
      :activate
  ]

  class << self
    def available_actions
      GENERAL + COMMENTS + MERGE_REQUESTS + MASS + GIT
    end

    def action_exists?(action)
      action = action.to_sym if action.is_a? String
      available_actions.include? action
    end

    def push_actions
      [ :pushed,
        :created_branch,
        :deleted_branch,
        :created_tag,
        :deleted_tag ]
    end

    def push_action?(action)
      action = action.to_sym if action.is_a? String
      push_actions.include? action
    end
  end
end
