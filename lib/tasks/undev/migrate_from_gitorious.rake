require 'logger'

namespace :undev do

  @import_log = Logger.new('import.log')
  @logger = Logger.new('path_changes.txt')

  #  ActiveRecord::Base.observers.disable :all

  desc "Migrate All data from gitorious to gitolite"
  task migrate: :environment do
    Project.destroy_all
    Group.destroy_all
    UserTeam.destroy_all
    User.destroy_all

    @import_log.info "create default admin"
    @admin = User.new
    @admin.username = "admin"
    @admin.name = "Admin"
    @admin.password = "123456"
    @admin.projects_limit = 100
    @admin.email = "admin@undev.cc"
    @admin.blocked = false
    @admin.admin = true
    @admin.save

    Rake::Task["undev:migrate:users"].invoke
    Rake::Task["undev:migrate:teams"].invoke
    Rake::Task["undev:migrate:projects"].invoke
    Rake::Task["undev:migrate:repositories"].invoke
    Rake::Task["undev:migrate:subscriptions:favorites"].invoke
    Rake::Task["undev:migrate:events"].invoke
  end

  namespace :migrate do

    desc "Migrate users from gitorious to gitlab"
    task users: :environment do

      user_count = Legacy::User.count

      @import_log.info "Start migrate users".yellow
      @import_log.info "Users count: #{user_count}"
      @import_log.info ""

      step = 0

      Gitlab::Event::Action.current_user = User.first

      Legacy::User.find_each do |user|
        unless User.find_by_username(user.login)
          new_user = User.new

          new_user.username = user.login
          new_user.name = user.fullname.blank? ? user.login : user.fullname
          new_user.email = user.email
          new_user.blocked = (user.aasm_state != "terms_accepted")

          new_user.admin = user.is_admin
          new_user.projects_limit = 100

          new_user.created_at = user.created_at
          new_user.updated_at = user.updated_at

          keys = Legacy::SshKey.where(user_id: user.id)

          keys.each do |key|
            new_user.keys.new(key: key.key, title: "#{user.login} #{user.email} key")
          end

          new_user.force_random_password = true

          begin
            if new_user.save
              @import_log.info "Migrate user: #{user.login} (#{user.fullname}) with email #{user.email} succesfull"
            else
              @import_log.info "Migrate user: #{user.login} - #{user.id} failed"
              @import_log.info "Errors: #{new_user.errors.inspect}"
            end
          rescue Exception => e
            @import_log.info "Migrate user: #{user.login} - #{user.id} FUCK!"
            @import_log.info "Errors: #{e.inspect}"
            puts e.backtrace
            puts ""
            puts ""
            puts ""
          end

          step += 1
          @import_log.info "#{user_count - step} is left"
          @import_log.info ""
        end
      end
      @import_log.info "Funish import users".green
    end


    desc "Migrate user teams from gitorious ti gitlab"
    task teams: :environment do

      teams_count = Legacy::Group.count

      @import_log.info "Start Teams of users"
      @import_log.info "Teams count: #{teams_count}"
      @import_log.info ""

      step = 0

      Gitlab::Event::Action.current_user = User.first

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
              @import_log.info "Migrate Team of users: #{team.name} succesfull"
            else
              @import_log.info "Migrate Team of users: #{group.name} - #{group.id} failed"
              @import_log.info "Errors: #{team.errors.inspect}"
            end

            # Members
            @import_log.info "Add members to team".yellow
            group.memberships.each do |group_member|
              user = User.find_by_username(group_member.user.login)
              if user
                is_admin = group_member.role.kind == 0 ? true : false
                permission = is_admin ? UsersProject.access_roles["Master"] : UsersProject.access_roles["Developer"]

                team.add_member(user, permission, is_admin)
                print ".".green
              end
            end
          rescue Exception => e
            @import_log.info "Migrate Team of users: #{group.name} - #{group.id} FUCK!"
            @import_log.info "Errors: #{e.inspect}"
          end
        end

        step += 1
        @import_log.info "#{teams_count - step} is left"
        @import_log.info ""

      end
      @import_log.info "Finish import user teams".green
    end

    desc "Migrate Projects from gitorius to gitlab"
    task projects: :environment do

      projects_count = Legacy::Project.count
      @import_log.info "Start migrate projects"
      @import_log.info "Projects count: #{projects_count}"

      Gitlab::Event::Action.current_user = User.first

      Legacy::Project.find_each do |project|

        unless Group.find_by_path(project.slug)
          unless Legacy::User.find_by_login(project.slug)
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
                  @import_log.info "Project #{group.name} processed succesfull"
                else
                  @import_log.info "Project #{project.title} - #{project.id} fail"
                  @import_log.info "Errors: #{group.errors.inspect}"
                end

              rescue Exception => e
                @import_log.info "Migrate project: #{project.title} - #{project.id} FUCK!"
                @import_log.info "Errors: #{e.inspect}"
              end
            end
          end
        end
      end
      @import_log.info "Finish import project groups".green
    end

    desc "Migrate Repositories from gitorious to gitlab"
    task repositories: :environment do

      repo_count = Legacy::Repository.count
      @import_log.info "Start migrate repositories from gitorius to gitlab".yellow
      @import_log.info "Repository count: #{repo_count}"

      root = Gitlab.config.gitlab_shell.repos_path

      Gitlab::Event::Action.current_user = User.first

      @shell = Gitlab::Shell.new

      Legacy::Repository.actual.each do |repo|

        group = Group.find_by_name(repo.project.slug)
        user = User.find_by_username(repo.project.slug)

        project = Project.new

        if group
          project.group = group # unless group.projects.find_by_name(repo.name)
        else
          project.namespace_id = user.namespace_id
        end

        project.name = repo.name
        project.description = repo.description
        project.issues_tracker = "redmine"

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

          #project.group = Group.find_by_path(repo.project.slug)

          project.path = repo.name.dup.parameterize
          project.public = (repo.project.private == false)

          begin
            if project.save
              @import_log.info "Repository #{project.name} processed succesfull"
              @import_log.info "Clone repo from gitorious: "

              project_path = File.join(root, "#{project.path_with_namespace}.git")

              system("rm -rf #{project_path}") if File.exists?(project_path)

              unless File.exists?(project_path)
                @shell.import_repository(project.path_with_namespace, repo.git_clone_url)

                @logger.info "#{repo.hashed_path}.git;#{project_path}"

                @import_log.info "OK".green
              else
                @import_log.info "Repo already exist!".red
              end

              @import_log.info "Migrate committerships:"

              master_users = repo.committerships.admins.users

              develop_users = repo.committerships.committers.users
              develop_users = develop_users - master_users

              report_users = repo.committerships.reviewers.users
              report_users = report_users - [master_users + develop_users]

              master_teams = repo.committerships.admins.groups

              develop_teams = repo.committerships.committers.groups
              develop_teams = develop_teams - master_teams

              report_teams = repo.committerships.reviewers.groups
              report_teams = report_teams - [master_teams + develop_teams]


              @import_log.info "Add masters to project"
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

              @import_log.info "Add developers to project"
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

              @import_log.info "Add reporters to project"
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

              @import_log.info "Delegate to team with MAX master role"
              master_teams.each do |mt|
                team = UserTeam.find_by_path(Legacy::Group.find_by_id(mt.committer_id).name)
                if team
                  permission = UsersProject.access_roles["Master"]
                  team.assign_to_project(project, permission)
                end
                print ".".green
              end

              @import_log.info "Delegate to team with MAX developer role"
              develop_teams.each do |dt|
                team = UserTeam.find_by_path(Legacy::Group.find_by_id(dt.committer_id).name)
                if team
                  permission = UsersProject.access_roles["Developer"]
                  team.assign_to_project(project, permission)
                end
                print ".".green
              end

              @import_log.info "Delegate to team with MAX reporter role"
              report_teams.each do |rt|
                team = UserTeam.find_by_path(Legacy::Group.find_by_id(rt.committer_id).name)
                if team
                  permission = UsersProject.access_roles["Reporter"]
                  team.assign_to_project(project, permission)
                end
                print ".".green
              end

            else
              @import_log.info "Repository #{repo.name} - #{repo.id} fail"
              @import_log.info "Errors: #{project.errors.inspect}"
            end

          rescue Exception => e
            @import_log.info "Migrate project: #{repo.name} - #{repo.id} FUCK!".red
            @import_log.info "Errors: #{e.inspect}"
          end

        end
      end
    end

    desc "Migrate Events"
    task events: :environment do
      @import_log.info "Remove all old events".yellow
      Event.destroy_all
      @import_log.info "Events removed.".green

      Rake::Task["undev:migrate:events:committers"].invoke
      Rake::Task["undev:migrate:events:repositories"].invoke
    end

    namespace :subscriptions do
      desc "Migrate Favorites from Gitorius to Gitlab"
      task favorites: :environment do

        @import_log.info "Start import favorite subscriptions".green
        @import_log.info "Favorites count: #{Legacy::Favorite.by_email.count}"

        Gitlab::Event::Action.current_user = User.first

        Legacy::Favorite.by_email.find_each do |favorite|
          begin
            case favorite.watchable_type
            when "Repository"
              project = Project.find_by_path(Legacy::Repository.find(favorite.watchable_id).name)
              user = User.find_by_username(favorite.user.login) if favorite.user
              if project && user
                Gitlab::Event::Subscription.subscribe(user, :all, project, :all)
                @import_log.info "Import subscription to #{project.name} for #{user.name} successfull".green
              else
                @import_log.info "Import subscription #{favorite.id} failed".red
              end
            when "Project"
              group = Group.find_by_path(Legacy::Project.find(favorite.watchable_id).slug)
              user = User.find_by_username(favorite.user.login) if favorite.user
              if group && user
                Gitlab::Event::Subscription.subscribe(user, :all, group, :all)
                @import_log.info "Import subscription to #{group.name} for #{user.name} successfull".green
              else
                @import_log.info "Import subscription #{favorite.id} failed".red
              end
            when "MergeRequest"
            else

            end
          rescue
          end
        end
      end
    end

    namespace :events do
      desc "Migrate project events"
      task repositories: :environment do

        @import_log.info "Start import information about repository activity".green
        @import_log.info "Events count: #{Legacy::Event.push_events.repository_events(nil).count}"

        Gitlab::Event::Action.current_user = User.first

        Legacy::Event.push_events.repository_events(nil).find_each do |event|

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

              OldEvent.create(
                project: project,
                action: OldEvent::PUSHED,
                data: data,
                author_id: data[:user_id],
                created_at: event.created_at,
                updated_at: event.updated_at
              )

              print "p".green

            when Legacy::Action::PUSH_SUMMARY

              oldrev, newrev, ref, commits = event.data.split "$"
              data = project.post_receive_data(oldrev, newrev, ref, user)

              OldEvent.create(
                project: project,
                action: OldEvent::PUSHED,
                data: data,
                author_id: data[:user_id],
                created_at: event.created_at,
                updated_at: event.updated_at
              )

              print "P".green

            end
          end
        end
        @import_log.info
        @import_log.info "OK".green
        @import_log.info
      end

      desc "Commiters information"
      task committers: :environment do

        @import_log.info "Start import information about repository committers".green
        @import_log.info "Committers count: #{Legacy::Event.committers_events.repository_events(nil).count}"

        Gitlab::Event::Action.current_user = User.first

        Legacy::Event.committers_events.repository_events(nil).find_each do |event|

          project = Project.find_by_path(Legacy::Repository.find(event.target_id).name)
          luser = Legacy::User.find_by_fullname(event.data)
          user = User.find_by_username(luser.login) if luser

          if project && user
            case event.action
            when Legacy::Action::ADD_COMMITTER

              OldEvent.create(
                project_id: project.id,
                action: OldEvent::JOINED,
                author_id: user.id,
                created_at: event.created_at,
                updated_at: event.updated_at
              )

              print "+".green

            when Legacy::Action::REMOVE_COMMITTER
              OldEvent.create(
                project_id: project.id,
                action: OldEvent::LEFT,
                author_id: user.id,
                created_at: event.created_at,
                updated_at: event.updated_at
              )

              print "-".green

            end

          end

        end

        @import_log.info ""
        @import_log.info "OK".green
        @import_log.info ""
      end
    end
  end
end
