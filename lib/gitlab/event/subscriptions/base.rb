module Gitlab
  module Event
    module Subscriptions
      class Base

        class << self
          def can_subscribe?(user, action, target, source)
            return true
          end
        end

      end
    end
  end
end

Dir[File.dirname(__FILE__) << "/**/*.rb"].each {|f| require f}
