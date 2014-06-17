module API
  module Entities
    class UserSafe < Grape::Entity
      expose :name, :username
    end

    class UserBasic < UserSafe
      expose :id, :state, :avatar_url
    end

    class User < UserBasic
      expose :created_at
      expose :is_admin?, as: :is_admin
      expose :bio, :skype, :linkedin, :twitter, :website_url
    end

    class UserFull < User
      expose :email
      expose :theme_id, :color_scheme_id, :extern_uid, :provider
      expose :can_create_group?, as: :can_create_group
      expose :can_create_project?, as: :can_create_project
    end

    class UserLogin < UserFull
      expose :private_token
    end

    class Hook < Grape::Entity
      expose :id, :url, :created_at
    end

    class ProjectHook < Hook
      expose :project_id, :push_events, :issues_events, :merge_requests_events
    end

    class ForkedFromProject < Grape::Entity
      expose :id
      expose :name, :name_with_namespace
      expose :path, :path_with_namespace
    end

    class Project < Grape::Entity
      expose :id, :description, :default_branch
      expose :public?, as: :public
      expose :archived?, as: :archived
      expose :visibility_level, :ssh_url_to_repo, :http_url_to_repo, :web_url
      expose :owner, using: Entities::UserBasic, unless: ->(project, options) { project.group }
      expose :name, :name_with_namespace
      expose :path, :path_with_namespace
      expose :issues_enabled, :merge_requests_enabled, :wiki_enabled, :snippets_enabled, :created_at, :last_activity_at
      expose :namespace
      expose :forked_from_project, using: Entities::ForkedFromProject, :if => lambda{ | project, options | project.forked? }
    end

    class TargetSubscription < Grape::Entity
      expose :id do |subscription, options|
        subscription.target_id
      end

      expose :namespace do |subscription, options|
        if subscription.target.respond_to?(:namespace)
          subscription.target.namespace.human_name
        end
      end

      expose :name do |subscription, options|
        subscription.target.try(:name)
      end

      expose :link do |subscription, options|
        h = Rails.application.routes.url_helpers

        case subscription.target.class.name
          when 'Project'
            h.project_path(subscription.target)
          when 'Team'
            h.team_path(subscription.target)
          when 'Group'
            h.group_path(subscription.target)
          when 'User'
            h.user_path(subscription.target)
          else
            ''
        end
      end

      expose :options do |subscription, options|
        available_sources = subscription.target.class.watched_sources.map(&:to_s)
        sources = subscription.options

        available_sources.reduce({}) do |response, source|
          response[source] = sources.include?(source)
          response
        end
      end

      expose :adjacent do |subscription, options|
        target = subscription.target
        user = subscription.user

        if target.class.watched_adjacent_sources.any?
          adjacent = options[:user].auto_subscriptions.adjacent(target.class.name, target.id)
            .pluck(:target).map(&:to_sym)

          target.class.watched_adjacent_sources.reduce({}) do |response, source|
            response[source] = adjacent.include?(source)
            response
          end
        else
          {}
        end
      end
    end

    class ProjectMember < UserBasic
      expose :project_access, as: :access_level do |user, options|
        options[:project].users_projects.find_by(user_id: user.id).project_access
      end
    end

    class TeamMember < UserBasic
      expose :permission, as: :access_level do |user, options|
        options[:team].team_user_relationships.find_by(user_id: user.id).permission
      end
    end

    class TeamProject < Project
      expose :greatest_access, as: :greatest_access_level do |project, options|
        options[:team].team_project_relationships.find_by(project_id: project.id).greatest_access
      end
    end

    class Group < Grape::Entity
      expose :id, :name, :path, :owner_id
    end

    class GroupDetail < Group
      expose :projects, using: Entities::Project
    end

    class GroupMember < UserBasic
      expose :group_access, as: :access_level do |user, options|
        options[:group].users_groups.find_by(user_id: user.id).group_access
      end
    end

    class Team < Grape::Entity
      expose :id, :name, :path, :creator_id
    end

    class TeamDetail < Team
      expose :projects, using: Entities::Project
    end

    class TeamMember < UserBasic
      expose :team_access, as: :access_level do |user, options|
        options[:team].team_users_relationships.find_by(user_id: user.id).team_access
      end
    end

    class RepoObject < Grape::Entity
      expose :name

      expose :commit do |repo_obj, options|
        if repo_obj.respond_to?(:commit)
          repo_obj.commit
        elsif options[:project]
          options[:project].repository.commit(repo_obj.target)
        end
      end

      expose :protected do |repo, options|
        if options[:project]
          options[:project].protected_branch? repo.name
        end
      end
    end

    class RepoTreeObject < Grape::Entity
      expose :id, :name, :type

      expose :mode do |obj, options|
        filemode = obj.mode.to_s(8)
        filemode = "0" + filemode if filemode.length < 6
        filemode
      end
    end

    class RepoCommit < Grape::Entity
      expose :id, :short_id, :title, :author_name, :author_email, :created_at
    end

    class RepoCommitDetail < RepoCommit
      expose :parent_ids, :committed_date, :authored_date
    end

    class ProjectSnippet < Grape::Entity
      expose :id, :title, :file_name
      expose :author, using: Entities::UserBasic
      expose :expires_at, :updated_at, :created_at
    end

    class ProjectEntity < Grape::Entity
      expose :id, :iid
      expose (:project_id) { |entity| entity.project.id }
      expose :title, :description
      expose :state, :created_at, :updated_at
    end

    class Milestone < ProjectEntity
      expose :due_date
    end

    class Issue < ProjectEntity
      expose :label_list, as: :labels
      expose :milestone, using: Entities::Milestone
      expose :assignee, :author, using: Entities::UserBasic
    end

    class MergeRequest < ProjectEntity
      expose :target_branch, :source_branch, :upvotes, :downvotes
      expose :author, :assignee, using: Entities::UserBasic
      expose :source_project_id, :target_project_id
      expose :label_list, as: :labels
    end

    class SSHKey < Grape::Entity
      expose :id, :title, :key, :created_at
    end

    class Note < Grape::Entity
      expose :id
      expose :note, as: :body
      expose :attachment_identifier, as: :attachment
      expose :author, using: Entities::UserBasic
      expose :created_at
    end

    class MRNote < Grape::Entity
      expose :note
      expose :author, using: Entities::UserBasic
    end

    class Event < Grape::Entity
      expose  :action, :author_id
      expose :target_id, :target_type
      expose :source_id, :source_type
      expose :data
      expose :created_at
    end

    class Namespace < Grape::Entity
      expose :id, :path, :kind
    end

    class Subscription < Grape::Entity
      expose :id
    end

    class ProjectAccess < Grape::Entity
      expose :project_access, as: :access_level
      expose :notification_level
    end

    class GroupAccess < Grape::Entity
      expose :group_access, as: :access_level
      expose :notification_level
    end

    class ProjectWithAccess < Project
      expose :permissions do
        expose :project_access, using: Entities::ProjectAccess do |project, options|
          project.users_projects.find_by(user_id: options[:user].id)
        end

        expose :group_access, using: Entities::GroupAccess do |project, options|
          if project.group
            project.group.users_groups.find_by(user_id: options[:user].id)
          end
        end
      end
    end

    class Label < Grape::Entity
      expose :name
    end

    class RepoDiff < Grape::Entity
      expose :old_path, :new_path, :a_mode, :b_mode, :diff
      expose :new_file, :renamed_file, :deleted_file
    end

    class Compare < Grape::Entity
      expose :commit, using: Entities::RepoCommit do |compare, options|
        if compare.commit
          Commit.new compare.commit
        end
      end
      expose :commits, using: Entities::RepoCommit do |compare, options|
        Commit.decorate compare.commits
      end
      expose :diffs, using: Entities::RepoDiff do |compare, options|
        compare.diffs
      end

      expose :compare_timeout do |compare, options|
        compare.timeout
      end

      expose :same, as: :compare_same_ref
    end
  end
end
