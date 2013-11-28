module Projects
  module Tags
    class CreateContext < Projects::BaseContext
      def execute
        project.repository.add_tag(params[:tag_name], params[:ref])

        if new_tag = project.repository.find_tag(params[:tag_name])
          OldEvent.create_ref_event(project, current_user, new_tag, 'add', 'refs/tags')

          @push_data = {
            before: "0000000000000000000000000000000000000000",
            after: new_tag.commit.id,
            ref: "refs/tags/" << new_tag,
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
