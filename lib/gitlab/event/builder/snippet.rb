module Gitlab
  module Event
    module Builder
      class Snippet < Gitlab::Event::Builder::Base
        include Gitlab::Event::Action::Snippet

        class << self
          def can_build?(action, data)
            known_action = known_action? action
            known_source = data.is_a? ::Snippet
            known_source && known_action
          end

          def build(action, source, user, data)
            meta = parse_action(action)
            meta[:action]

            ::Event.new(action: ::Event::Action.action_by_name(meta[:action]), source: source, data: data.to_json, author: user)
          end
        end
      end
    end
  end
end
