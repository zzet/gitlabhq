module Projects
  module Tags
    class RemoveContext < Projects::Tags::BaseContext
      def execute
        if tag && project.repository.rm_tag(tag.name)
          OldEvent.create_ref_event(project, current_user, tag, 'rm', 'refs/tags')

          @push_data = {
            before: tag.commit.id,
            after: "0000000000000000000000000000000000000000",
            ref: "refs/tags/" << tag,
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
