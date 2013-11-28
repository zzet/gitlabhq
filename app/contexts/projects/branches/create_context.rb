module Projects
  module Branches
    class CreateContext < Projects::BaseContext
      def execute
        project.repository.add_branch(params[:branch_name], params[:ref])

        if new_branch = project.repository.find_branch(params[:branch_name])
          OldEvent.create_ref_event(project, current_user, new_branch, 'add')
        end
      end
    end
  end
end
