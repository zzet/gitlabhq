module Projects
  module ProtectedBranchs
    class RemoveContext < Projects::ProtectedBranchs::BaseContext
      def execute
        protected_branch.destroy

        receive_delayed_notifications
      end
    end
  end
end
