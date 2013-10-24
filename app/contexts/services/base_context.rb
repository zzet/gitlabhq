module Services
  class BaseContext < ::BaseContext
    attr_accessor :service, :current_user, :params

    def initialize(user, service, params = {})
      @service, @current_user, @params = service, user, params.dup
    end
  end
end
