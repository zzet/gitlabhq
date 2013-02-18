module Gitlab
  module Event
    module Action
      module Base
        extend ActiveSupport::Concern

        included do
          class << self
            def avaliable_actions
              raise NotImplementedError
            end

            def known_action?(action)
              meta = parse_action(action)
              avaliable_actions.include? meta[:action]
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
end
