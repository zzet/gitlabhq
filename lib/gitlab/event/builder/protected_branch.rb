module Gitlab
  module Event
    module Builder
      class ProtectedBranch < Gitlab::Event::Builder::Base
        @avaliable_action = [:created,
                             :deleted,
                             :updated
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            known_source = data.is_a? ::ProtectedBranch
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
