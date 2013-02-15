module Gitlab
  module Event
    module Builder
      class Service < Gitlab::Event::Builder::Base
        @avaliable_action = [:created,
                             :deleted,
                             :updated
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            known_target = data[:target].is_a? ::Service
            known_target && known_action
          end

          def build(action, target, user, data)
            meta = parse_action(action)
            meta[:action]

            ::Event.new(action: ::Event::Action.action_by_name(meta[:action]), target: target, data: data.to_json, author: user)
          end
        end
      end
    end
  end
end
