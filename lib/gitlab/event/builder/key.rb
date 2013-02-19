module Gitlab
  module Event
    module Builder
      class Key < Gitlab::Event::Builder::Base
        include Gitlab::Event::Action::Key

        class << self
          def can_build?(action, data)
            known_action = known_action? action
            known_source = data.is_a? ::Key
            known_source && known_action
          end

          def build(action, source, user, data)
            meta = parse_action(action)
            meta[:action]
            target = source

            ::Event.new(action: ::Event::Action.action_by_name(meta[:action]), source: source, data: data.to_json, author: user, target: target)
          end
        end
      end
    end
  end
end
