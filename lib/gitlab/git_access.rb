module Gitlab
  class GitAccess
    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }
    PUSH_COMMANDS = %w{ git-receive-pack }

    attr_reader :params, :project, :git_cmd, :user

    def allowed?(actor, cmd, project, ref = nil, oldrev = nil, newrev = nil, forced_push = false)
      case cmd
      when *DOWNLOAD_COMMANDS
        case actor
        when User
          download_allowed?(actor, project)
        when DeployKey
          actor.projects.include?(project)
        when ServiceKey
          service = actor.services.with_project(project).first
          if service.present?
            service.allowed_clone?(actor)
          else
            false
          end
        when Key
          download_allowed?(actor.user, project)
        else
          raise 'Wrong actor'
        end
      when *PUSH_COMMANDS
        case actor
        when User
          push_allowed?(actor, project, ref, oldrev, newrev, forced_push)
        when DeployKey
          # Deploy key not allowed to push
          return false
        when ServiceKey
          service = actor.services.with_project(project).first
          if service.present?
            if project.protected_branch?(ref)
              services.allowed_protected_push?(actor)
            else
              service.allowed_push?(actor)
            end
          else
            false
          end
        when Key
          push_allowed?(actor.user, project, ref, oldrev, newrev, forced_push)
        else
          raise 'Wrong actor'
        end
      else
        false
      end
    end

    def download_allowed?(user, project)
      if user && user_allowed?(user)
        user.can?(:download_code, project)
      else
        false
      end
    end

    def push_allowed?(user, project, ref, oldrev, newrev, forced_push)
      if user && user_allowed?(user)
        action = if project.protected_branch?(ref)
                   # we dont allow force push to protected branch
                   if forced_push.to_s == 'true'
                     :force_push_code_to_protected_branches
                   # and we dont allow remove of protected branch
                   elsif newrev =~ /0000000/
                     :remove_protected_branches
                   else
                     :push_code_to_protected_branches
                   end
                 elsif project.repository && project.repository.tag_names.include?(ref)
                   # Prevent any changes to existing git tag unless user has permissions
                   :admin_project
                 else
                   :push_code
                 end
        user.can?(action, project)
      else
        false
      end
    end

    private

    def user_allowed?(user)
      Gitlab::UserAccess.allowed?(user)
    end
  end
end
