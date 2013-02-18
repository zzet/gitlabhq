module Gitlab
  module Event
    module Builder
      class Base
        class << self
          def can_build?(action, data)
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
