class Ability
  class << self
    def allowed(user, subject)
      return [] unless user.kind_of?(User)
      return [] if user.blocked?

      case subject.class.name
      when "Project" then project_abilities(user, subject)
      when "Issue" then issue_abilities(user, subject)
      when "Note" then note_abilities(user, subject)
      when "ProjectSnippet" then project_snippet_abilities(user, subject)
      when "PersonalSnippet" then personal_snippet_abilities(user, subject)
      when "MergeRequest" then merge_request_abilities(user, subject)
      when "Group" then group_abilities(user, subject)
      when "Team" then team_abilities(user, subject)
      when "Namespace" then namespace_abilities(user, subject)
      else []
      end.concat(global_abilities(user))
    end

    def global_abilities(user)
      rules = []
      rules << :create_group if user.can_create_group
      rules
    end

    def project_abilities(user, project)
      rules = []

      team = project.team

      teams = project.teams
      is_team_admin = teams.inject(false) { |a, b| a = a || b.admin?(user)}

      # Rules based on role in project
      if team.masters.include?(user) || is_team_admin
        rules << project_master_rules

      elsif team.developers.include?(user)
        rules << project_dev_rules

      elsif team.reporters.include?(user)
        rules << project_report_rules

      elsif team.guests.include?(user)
        rules << project_guest_rules
      end

      if project.public?
        rules << public_project_rules
      end

      if project.owner == user || user.admin?
        rules << project_admin_rules
      end

      if project.group && project.group.owners.include?(user)
        rules << project_admin_rules
      end

      rules.flatten
    end

    def public_project_rules
      [
        :download_code,
        :fork_project,
        :read_project,
        :read_wiki,
        :read_issue,
        :read_milestone,
        :read_project_snippet,
        :read_team_member,
        :read_merge_request,
        :read_note,
        :write_issue,
        :write_note
      ]
    end

    def project_guest_rules
      [
        :read_project,
        :read_wiki,
        :read_issue,
        :read_milestone,
        :read_project_snippet,
        :read_team_member,
        :read_merge_request,
        :read_note,
        :write_project,
        :write_issue,
        :write_note
      ]
    end

    def project_report_rules
      project_guest_rules + [
        :download_code,
        :fork_project,
        :write_project_snippet
      ]
    end

    def project_dev_rules
      project_report_rules + [
        :write_merge_request,
        :write_wiki,
        :push_code
      ]
    end

    def project_master_rules
      rules = project_dev_rules << [
        :push_code_to_protected_branches,
        :modify_issue,
        :modify_project_snippet,
        :modify_merge_request,
        :admin_issue,
        :admin_milestone,
        :admin_project_snippet,
        :admin_team_member,
        :admin_merge_request,
        :admin_note,
        :admin_wiki,
        :change_namespace,
        :change_public_mode,
        :rename_project,
        :remove_project,
        :admin_project
      ]

      rules << [:change_public_via_git_mode] if Gitlab.config.gitlab.git_daemon_enabled
      rules.flatten
    end

    def project_admin_rules
      project_master_rules
    end

    def group_abilities user, group
      rules = []

      # Only group owner and administrators can manage group
      if group.owners.include?(user) || user.admin? || group.admins.include?(user)
        rules << [
          :manage_group,
          :manage_namespace
        ]
      end

      rules.flatten
    end

    def team_abilities user, team
      rules = []

      # Only group owner and administrators can manage group
      if team.owners.include?(user) || user.admin? || team.admins.include?(user)
        rules << [
          :manage_team,
          :remove_team
        ]
      end

      rules.flatten
    end

    def namespace_abilities user, namespace
      rules = []

      # Only namespace owner and administrators can manage it
      if namespace.owner == user || user.admin?
        rules << [
          :manage_namespace
        ]
      end

      rules.flatten
    end

    [:issue, :note, :project_snippet, :personal_snippet, :merge_request].each do |name|
      define_method "#{name}_abilities" do |user, subject|
        if subject.author == user
          [
            :"read_#{name}",
            :"write_#{name}",
            :"modify_#{name}",
            :"admin_#{name}"
          ]
        elsif subject.respond_to?(:assignee) && subject.assignee == user
          [
            :"read_#{name}",
            :"write_#{name}",
            :"modify_#{name}",
          ]
        else
          subject.respond_to?(:project) ? project_abilities(user, subject.project) : []
        end
      end
    end
  end
end
