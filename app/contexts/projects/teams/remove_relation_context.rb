module Projects
  module Teams
    class RemoveRelationContext < Projects::Teams::BaseContext
      def execute
        ::Teams::Projects::RemoveRelationContext.new(current_user, team, project).execute
      end
    end
  end
end
