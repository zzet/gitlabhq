module Gitlab
  module Event
    module Builder
      class ProtectedBranch < Gitlab::Event::Builder::Base
        class << self
          def can_build?(action, data)
            known_action = known_action? action, ::ProtectedBranch.available_actions
            known_source = data.is_a? ::ProtectedBranch
            known_source && known_action
          end

          def build(action, source, user, data)
            meta = parse_action(action)
            meta[:action]

            target = source

            ::Event.new(action: meta[:action],
                        source: source, data: data.to_json, author: user, target: target)
          end
        end
      end
    end
  end
end
