namespace :undev do
  namespace :migrate do

    desc "Migrate users from gitorious to gitlab"
    task :users => :environment do

      user_count = Legacy::User.count
      puts "Start migrate users"
      puts "Users count: #{user_count}"
      puts ""

      step = 0

      Legacy::User.find_each do |user|
        unless User.find_by_username(user.login)
          new_user = User.new

          new_user.username = user.login
          new_user.name = user.fullname.blank? ? user.login : user.fullname
          new_user.email = user.email
          new_user.blocked = (user.aasm_state != "terms_accepted")

          new_user.admin = user.is_admin

          new_user.created_at = user.created_at
          new_user.updated_at = user.updated_at

          key = Legacy::SshKey.find_by_user_id(user.id)
          new_user.keys.new(key: key.key, title: "#{user.login} #{user.email} key") if key

          new_user.force_random_password = true

          begin
            if new_user.save
              puts "Migrate user: #{user.login} (#{user.fullname}) with email #{user.email} succesfull"
            else
              puts "Migrate user: #{user.login} - #{user.id} failed"
              puts "Errors: #{new_user.errors.inspect}"
            end
          rescue Exception => e
            puts "Migrate user: #{user.login} - #{user.id} FUCK!"
            puts "Errors: #{e.inspect}"
          end

          step =+ 1
          puts "#{user_count - step} is left"
          puts ""
        end
      end
    end


    desc "Migrate user teams from gitorious ti gitlab"
    task :teams => :environment do

      teams_count = Legacy::Group.count
      puts "Start Teams of users"
      puts "Teams count: #{teams_count}"
      puts ""

      step = 0

      Legacy::Group.find_each do |group|
        unless UserTeam.find_by_path(group.name)
          team = UserTeam.new

          team.name = group.name
          team.path = group.name
          team.description = group.description

          team.created_at = group.created_at
          team.updated_at = group.updated_at

          group_owner = Legacy::User.find_by_id(group.user_id)
          team.owner = User.find_by_username(group_owner.login)

          begin
            if team.save
              puts "Migrate Team of users: #{team.name} succesfull"
            else
              puts "Migrate Team of users: #{group.name} - #{group.id} failed"
              puts "Errors: #{team.errors.inspect}"
            end
            # Members
            puts "Add members to team "
            group.memberships.each do |group_member|
              user = User.find_by_username(group_member.user.login)
              if user
                is_admin = group_member.role.kind == 0 ? true : false
                permission = is_admin ? UsersProject.access_roles["Master"] : UsersProject.access_roles["Developer"]

                team.add_member(user, permission, is_admin)
                print ". "
              end
            end
          rescue Exception => e
            puts "Migrate Team of users: #{group.name} - #{group.id} FUCK!"
            puts "Errors: #{e.inspect}"
          end
        end

        step =+ 1
        puts "#{teams_count - step} is left"
        puts ""

      end
    end

    desc "Migrate Projects from gitorius to gitlab"
    task :projects => :environment do

      projects_count = Legacy::Project.count
      puts "Start migrate projects"
      puts "Projects count: #{projects_count}"

      Legacy::Project.find_each do |project|

        unless Group.find_by_path(project.slug)
          group = Group.new

          owner_type = project.owner_type
          owner = case owner_type
                  when 'Group'
                    owner_group = Legacy::Group.find_by_id(project.owner_id)
                    User.find_by_username(owner_group.creator.login)
                  when 'User'
                    User.find_by_username(Legacy::User.find_by_id(project.owner_id).login)
                  end
          if owner
            group.name = project.title
            group.path = project.slug
            group.description = project.description

            group.owner = owner

            group.created_at = project.created_at
            group.updated_at = project.updated_at

            begin
              if group.save
                puts "Project #{group.name} processed succesfull"
              else
                puts "Project #{project.title} - #{project.id} fail"
                puts "Errors: #{group.errors.inspect}"
              end

            rescue Exception => e
              puts "Migrate project: #{project.title} - #{project.id} FUCK!"
              puts "Errors: #{e.inspect}"
            end
          end
        end
      end
    end

    desc "Migrate Repositories from gitorious to gitlab"
    task :repositories => :environment do

      repo_count = Legacy::Repository.count
      puts "Start migrate repositories from gitorius to gitlab"
      puts "Repository count: #{repo_count}"

      root = Gitlab.config.gitolite.repos_path

      Legacy::Repository.actual.each do |repo|

        unless Project.find_by_name(repo.name)

          project = Project.new

          project.name = repo.name
          project.description = repo.description
          #project.issues_tracker = "redmine"

          project.created_at = repo.created_at
          project.updated_at = repo.updated_at

          creator = User.find_by_username(repo.user.login)

          if creator
            project.creator = creator

            owner = case repo.owner_type
                    when 'Group'
                      owner_group = Legacy::Group.find_by_id(repo.owner_id)
                      User.find_by_username(owner_group.creator.login)
                    when 'User'
                      User.find_by_username(repo.user.login)
                    end

            project.group = Group.find_by_path(repo.project.slug)

            project.path = repo.name.dup.parameterize
            project.public = (repo.project.private == false)

            begin
              if project.save
                puts "Repository #{project.name} processed succesfull"
                puts "Clone repo from gitorious: "

                project_path = File.join(root, "#{project.path_with_namespace}.git")

                unless File.exists?(project_path)

                  cmds = [
                    "cd #{root} && sudo -u git -H git clone --bare #{repo.git_clone_url} ./#{project.path_with_namespace}.git",
                    "sudo ln -s ./lib/hooks/post-receive #{project_path}/hooks/post-receive",
                      "sudo chown git:git -R #{project_path}",
                      "sudo chmod 770 -R #{project_path}",
                  ]

                    cmds.each do |cmd|
                      puts cmd.yellow
                      `#{cmd}`
                    end

                    puts "OK".green
                else
                  puts "Repo already exist!".red
                end

                puts "Migrate committerships:"

                master_users = repo.committerships.admins.users

                develop_users = repo.committerships.committers.users
                develop_users = develop_users - master_users

                report_users = repo.committerships.reviewers.users
                report_users = report_users - [master_users + develop_users]

                master_teams = repo.committerships.admins.groups

                develop_teams = repo.committerships.committers.groups
                develop_teams =  develop_teams - master_teams

                report_teams = repo.committerships.reviewers.groups
                report_teams = report_teams - [master_teams + develop_teams]


                puts "Add masters to project"
                master_users.each do |mu|
                  user_ids = []
                  user = User.find_by_username(Legacy::User.find_by_id(mu.committer_id).login)
                  user_ids << user.id if user
                  permission = UsersProject.access_roles["Master"]
                  unless user_ids.blank?
                    project.team.add_users_ids(user_ids, permission)
                    if project.save
                      print ".".green
                    else
                      print ".".red
                    end
                  end
                end

                puts "Add developers to project"
                develop_users.each do |du|
                  user_ids = []
                  user = User.find_by_username(Legacy::User.find_by_id(du.committer_id).login)
                  user_ids << user.id if user
                  permission = UsersProject.access_roles["Developer"]
                  unless user_ids.blank?
                    project.team.add_users_ids(user_ids, permission)
                    if project.save
                      print ".".green
                    else
                      print ".".red
                    end
                  end
                end

                puts "Add reporters to project"
                report_users.each do |ru|
                  user_ids = []
                  user = User.find_by_username(Legacy::User.find_by_id(ru.committer_id).login)
                  user_ids << user.id if user
                  permission = UsersProject.access_roles["Reporter"]
                  unless user_ids.blank?
                    project.team.add_users_ids(user_ids, permission)
                    if project.save
                      print ".".green
                    else
                      print ".".red
                    end
                  end
                end

                puts "Delegate to team with MAX master role"
                master_teams.each do |mt|
                  team = UserTeam.find_by_path(Legacy::Group.find_by_id(mt.committer_id).name)
                  if team
                    permission = UsersProject.access_roles["Master"]
                    team.assign_to_project(project, permission)
                  end
                  print ".".green
                end

                puts "Delegate to team with MAX developer role"
                develop_teams.each do |dt|
                  team = UserTeam.find_by_path(Legacy::Group.find_by_id(dt.committer_id).name)
                  if team
                    permission = UsersProject.access_roles["Developer"]
                    team.assign_to_project(project, permission)
                  end
                  print ".".green
                end

                puts "Delegate to team with MAX reporter role"
                report_teams.each do |rt|
                  team = UserTeam.find_by_path(Legacy::Group.find_by_id(rt.committer_id).name)
                  if team
                    permission = UsersProject.access_roles["Reporter"]
                    team.assign_to_project(project, permission)
                  end
                  print ".".green
                end

              else
                puts "Repository #{repo.name} - #{repo.id} fail"
                puts "Errors: #{project.errors.inspect}"
              end

            rescue Exception => e
              puts "Migrate project: #{repo.name} - #{repo.id} FUCK!".red
              puts "Errors: #{e.inspect}"
            end

          end
        end
      end
    end

    desc "Migrate Events"
    task :events => :environment do
      Rake::Task["undev:migrate:events:committers"].invoke
      Rake::Task["undev:migrate:events:repositories"].invoke
    end

    namespace :events do
      desc "Migrate project events"
      task :repositories => :environment do

        puts "Start import information about repository activity".green
        puts "Events count: #{Legacy::Event.push_events.repository_events.count}"
        Legacy::Event.push_events.repository_events.find_each do |event|

          project = Project.find_by_path(Legacy::Repository.find(event.target_id).name)
          user = nil
          user = User.find_by_username(event.user.login) if event.user

          if project && user
            case event.action
            when Legacy::Action::COMMIT
              print "c".green
            when Legacy::Action::CREATE_BRANCH
              print "b".green
            when Legacy::Action::DELETE_BRANCH
              print "b".red
            when Legacy::Action::CREATE_TAG
              print "t".green
            when Legacy::Action::DELETE_TAG
              print "t".red
            when Legacy::Action::PUSH

              tmp = event.body.split " "
              data = project.post_receive_data(tmp[3], tmp[5], event.data, user)

              Event.create(
                project: project,
                action: Event::Pushed,
                data: data,
                author_id: data[:user_id],
                created_at: event.created_at,
                updated_at: event.updated_at
              )

              print "p".green

            when Legacy::Action::PUSH_SUMMARY

              oldrev, newrev, ref, commits = event.data.split "$"
              data = project.post_receive_data(oldrev, newrev, ref, user)

              Event.create(
                project: project,
                action: Event::Pushed,
                data: data,
                author_id: data[:user_id],
                created_at: event.created_at,
                updated_at: event.updated_at
              )

              print "P".green

            end
          end
        end
        puts
        puts "OK".green
        puts
      end

      desc "Commiters information"
      task :committers => :environment do

        puts "Start import information about repository committers".green
        puts "Committers count: #{Legacy::Event.committers_events.repository_events.count}"
        Legacy::Event.committers_events.repository_events.find_each do |event|

          project = Project.find_by_path(Legacy::Repository.find(event.target_id).name)
          luser = Legacy::User.find_by_fullname(event.data)
          user = User.find_by_username(luser.login) if luser

          if project && user
            case event.action
            when Legacy::Action::ADD_COMMITTER

              Event.create(
                project_id: project.id,
                action: Event::Joined,
                author_id: user.id,
                created_at: event.created_at,
                updated_at: event.updated_at
              )

              print "+".green

            when Legacy::Action::REMOVE_COMMITTER
              Event.create(
                project_id: project.id,
                action: Event::Left,
                author_id: user.id,
                created_at: event.created_at,
                updated_at: event.updated_at
              )

              print "-".green

            end

          end

        end

        puts ""
        puts "OK".green
        puts ""
      end
    end
  end
end
