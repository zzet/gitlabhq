module Projects
  module Tags
    class RemoveContext < Projects::Tags::BaseContext
      def execute
        if tag && project.repository.rm_tag(tag.name)
          Event.create_ref_event(project, current_user, tag, 'rm', 'refs/tags')
        end

        receive_delayed_notifications
      end
    end
  end
end
