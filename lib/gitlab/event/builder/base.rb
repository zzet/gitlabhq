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

          def known_action?(known_action_list, action)
            meta = parse_action(action)
            known_action_list.include? meta[:action]
          end

          def parse_action(action)
            info = action.split "."
            info.shift # Shift "gitlab"
            {
              action: info.shift.to_sym,
              details: info
            }
          end
        end
      end
    end
  end
end

Dir[File.dirname(__FILE__) << "/**/*.rb"].each {|f| require f}
