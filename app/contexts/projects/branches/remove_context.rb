module Projects
  module Branches
    class RemoveContext < Projects::Branches::BaseContext
      def execute
        if branch && project.repository.rm_branch(branch.name)
          OldEvent.create_ref_event(project, current_user, branch, 'rm')
        end

        receive_delayed_notifications
      end
    end
  end
end
