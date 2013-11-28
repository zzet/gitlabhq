module Projects
  module Branches
    class RemoveContext < Projects::Branches::BaseContext
      def execute
        if branch && project.repository.rm_branch(branch.name)
          OldEvent.create_ref_event(project, current_user, branch, 'rm')

          @push_data = {
            before: branch.commit.id,
            after: "0000000000000000000000000000000000000000",
            ref: "refs/heads/" << branch.name,
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

        receive_delayed_notifications
      end
    end
  end
end
