desc "Undev | Migrate teams data from one table to another"
namespace :undev do
  task migrate_teams_data: :environment do
    puts "Move teams".yellow
    Team.transaction do
      UserTeam.find_each do |ut|
        t = Team.new(name:        ut.name,
                     description: ut.description,
                     path:        ut.path,
                     creator_id:  ut.owner_id,
                     public:      false)
        t.created_at = ut.created_at
        t.updated_at = ut.updated_at

        if t.save
          puts "Team #{t.name} was succesfull created".green
          puts "Move members for #{t.name} team".yellow
          UserTeamUserRelationship.where(user_team_id: ut.id).find_each do |utur|
            u = User.find_by_id(utur.user_id)
            if u.present?
              if u.active?
                if t.team_user_relationships.create(user_id: utur.user_id, team_access: utur.permission)
                  puts "Add user #{u.name} to #{t.name} team - success"
                else
                  puts "Add user #{u.name} to #{t.name} team - success"
                end
              else
                puts "User #{u.name} was not added to #{t.name} team - user is inactive (banned)"
              end
            else
              puts "User with id #{utur.user_id} was not added to #{t.name} team - user is not found"
            end
          end

          puts "Assign #{t.name} team to groups".yellow
          UserTeamGroupRelationship.where(user_team_id: ut.id).find_each do |utgr|
            g = Group.find_by_id(utgr.group_id)
            if g.present?
              if t.team_group_relationships.create(group_id: g.id)
                puts "#{t.name} team was successed assigned to group #{g.name}"
              else
                puts "Assigment #{t.name} team to group #{g.name} was failed"
              end
            else
              puts "Group with id #{utgr.group_id} was not added to #{t.name} team - group is not found"
            end
          end

          puts "Assign #{t.name} team to projects".yellow
          UserTeamProjectRelationship.where(user_team_id: ut.id).find_each do |utpr|
            pr = Project.find_by_id(utpr.project_id)
            if pr.present?
              if t.groups_projects.where(id: pr.id).any?
                puts "#{t.name} team was not assigned to project #{pr.name_with_namespace} because team already assigned to group, which contain this project"
              else
                if t.team_project_relationships.create(project_id: utpr.project_id)
                  puts "#{t.name} team was successed assigned to project #{pr.name_with_namespace}"
                else
                  puts "Assigment #{t.name} team to project #{pr.name_with_namespace} was failed"
                end
              end
            else
              puts "Project with id #{utpr.project_id} was not added to #{t.name} team - project is not found"
            end
          end

        end
      end
    end
  end

  desc "Undev | Rebuild users lists in new teams and groups"
  task rebuild_users_lists: :environment do
    Team.transaction do
      Team.find_each do |t|
        puts "Try move #{t.name} members".yellow
        g = Group.find_by_path(t.path)
        if g.present?
          puts "Move #{t.name} members"

          guests      = t.guests.pluck(:id)
          reporters   = t.reporters.pluck(:id)
          developers  = t.developers.pluck(:id)
          masters     = t.masters.pluck(:id)
          g.add_users(guests,     Gitlab::Access::GUEST)
          g.add_users(reporters,  Gitlab::Access::REPORTER)
          g.add_users(developers, Gitlab::Access::DEVELOPER)
          g.add_users(masters,    Gitlab::Access::MASTER)
          puts "Move #{t.name} members finished".green

          g.team_group_relationships.where(team_id: t).destroy_all
          puts "Remove #{t.name} from #{g.name} group finished".green

          t.team_project_relationships.where(project_id: g.projects.pluck(:id)).destroy_all
          puts "Remove #{t.name} from #{g.name} projects finished".green
        end
      end
    end
  end

  desc "Undev | Clean projects members lists"
  task clean_projects_members_lists: :environment do
    Project.find_each do |pr|
      puts "#{pr.name_with_namespace} work".green
      pr.users_projects.find_each do |up|
        if pr.owner.id != up.user_id
          puts "#{up.user.name} in work".yellow
          gm = pr.groups_members.where(id: up.user_id)
          if gm.any?
            g = pr.group
            if g.present?
              gum = g.users_groups.find_by_user_id(up.user_id)
              if gum.present?
                if gum.group_access == up.project_access
                  puts "#{up.user.name} removed - it in group".red
                  up.destroy
                end
              end
            end
          end

          if up.persisted?
            tm = pr.teams_members.where(id: up.user_id)
            if tm.any?
              pr.teams.find_each do |pt|
                next unless up.persisted?

                tum = pt.team_user_relationships.find_by_user_id(up.user_id)
                if tum.present?
                  if tum.team_access == up.project_access
                    puts "#{up.user.name} removed - it in assigned team".red
                    up.destroy
                  end
                end
              end
            end
          end
        else
          puts "#{pr.owner.name} sciped - it's owner".green
        end
      end
    end
  end
end
