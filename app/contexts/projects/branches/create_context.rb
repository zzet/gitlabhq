module Projects
  module Branches
    class CreateContext < Projects::BaseContext
      def execute
        project.repository.add_branch(params[:branch_name], params[:ref])

        if new_branch = project.repository.find_branch(params[:branch_name])
          OldEvent.create_ref_event(project, current_user, new_branch, 'add')

          @push_data = {
            before: "0000000000000000000000000000000000000000",
            after: new_branch.commit.id,
            ref: "refs/heads/" << new_branch.name,
            user_id: current_user.id,
            user_name: current_user.name,
            project_id: project.id,
            repository: {
              name: project.name,
              url: project.url_to_repo,
              description: project.description,
              homepage: project.web_url,
            },
            commits: [],
            total_commits_count: 0
          }

          Gitlab::Event::Action.trigger :pushed, "Push_summary", current_user, { project_id: project.id, push_data: @push_data, source: :repository }
        end
      end
    end
  end
end
