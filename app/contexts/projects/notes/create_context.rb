module Projects
  module Notes
    class CreateContext < Projects::BaseContext
      def execute
        note = project.notes.new(params[:note])
        note.author = current_user
        note.save

        receive_delayed_notifications

        note
      end
    end
  end
end
