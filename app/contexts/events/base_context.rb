module Events
  class BaseContext < ::BaseContext
    attr_accessor :current_user, :events, :filter, :params, :feed

    def initialize(user, filter, params)
      @current_user, @filter, @params = user, filter, params
      @feed = ActivityFeed.new(current_user)
    end
  end
end
