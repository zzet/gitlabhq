module Gitlab
  module Event
    module Notification
      class Base

        class << self
          def test(action, data)
            raise NotImplementedError
          end

          def build(action, target, user, data)
            raise NotImplementedError
          end
        end
      end
    end
  end
end

Dir[File.dirname(__FILE__) << "/**/*.rb"].each {|f| require f}
