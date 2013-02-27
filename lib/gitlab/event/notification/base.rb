module Gitlab
  module Event
    module Notification
      class Base

        class << self
          def descendants
            # In production class cache :)
            Dir[File.dirname(__FILE__) << "/**/*.rb"].each {|f| load f} if super.blank?

            super
          end

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
