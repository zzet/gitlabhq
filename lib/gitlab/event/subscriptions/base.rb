module Gitlab
  module Event
    module Subscriptions
      class Base

        class << self
          def descendants
            # In production class cache :)
            Dir[File.dirname(__FILE__) << "/**/*.rb"].each {|f| load f} if super.blank?

            super
          end

          def can_subscribe?(user, action, target, source)
            return true
          end
        end

      end
    end
  end
end
