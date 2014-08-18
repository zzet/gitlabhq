module Projects
  class DestroyProject < Projects::Base
    def perform
      project = context[:project]

      if project.destroy
        context[:entity] = project
        context[:event] = :destroy

        log_info("Project \"#{project.name}\" was removed")
      else
        context.fail!(message: 'Unable destroy project')
      end
    end

    def rollback
      # Can we do something?
    end
  end
end