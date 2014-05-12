module Gitlab
  module Event
    class SyntheticActions
      TEAMS_ADD = 'teams_add'
      TEAMS_REMOVE = 'teams_remove'
      MEMBERSHIPS_ADD = 'memberships_add'
      MEMBERSHIPS_REMOVE = 'memberships_remove'
      MEMBERSHIPS_UPDATE = 'memberships_update'
      GROUPS_ADD = 'groups_add'
      PROJECTS_ADD = 'projects_add'
      IMPORT = 'import'

      ALL = [TEAMS_ADD, TEAMS_REMOVE, MEMBERSHIPS_ADD, MEMBERSHIPS_REMOVE,
         MEMBERSHIPS_UPDATE, GROUPS_ADD, PROJECTS_ADD, IMPORT]
    end
  end
end
