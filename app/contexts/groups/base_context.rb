module Groups
  class BaseContext < ::BaseContext
    attr_accessor :group, :current_user, :params

    def initialize(group, user, params = {})
      @group, @current_user, @params = group, user, params.dup
    end
  end
end