module Projects
  module Tags
    class CreateContext < Projects::BaseContext
      def execute
        project.repository.add_tag(params[:tag_name], params[:ref])

        if new_tag = project.repository.find_tag(params[:tag_name])
          Event.create_ref_event(project, current_user, new_tag, 'add', 'refs/tags')
        end
      end
    end
  end
end
