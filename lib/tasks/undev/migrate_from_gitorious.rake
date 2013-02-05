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
          #team.description = group.description

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
            #group.description = project.description

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
  end
end
