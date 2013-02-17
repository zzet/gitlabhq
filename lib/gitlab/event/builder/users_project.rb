module Gitlab
  module Event
    module Builder
      class UsersProject < Gitlab::Event::Builder::Base
        # Review
        @avaliable_action = [:created,
                             :deleted,
                             :updated
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            known_target = data.is_a? ::UsersProject
            known_target && known_action
          end

          def build(action, target, user, data)
            meta = parse_action(action)
            actions = []
            actions << meta[:action]
            case meta[:action]
            when :created
            when :updated
            when :deleted
            end

            ::Event.new(action: ::Event::Action.action_by_name(meta[:action]), target: target, data: data.to_json, author: user)
          end
        end
      end
    end
  end
end
