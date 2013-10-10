module Services
  class RemoveContext < Services::BaseContext
    def execute(role = :user)
      begin
        if role == :user && service.children.any?
          return false
        end

        Service.transaction do
          service.children.each do |children|
            children.destroy
          end

          service.destroy
        end
      rescue
        return false
      end

      true
    end
  end
end
