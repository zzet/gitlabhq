module Gitlab
  module Event
    module Builder
      class UserTeamProjectRelationship < Gitlab::Event::Builder::Base
        # Review
        @avaliable_action = [:created,
                             :deleted,
                             :updated
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            known_source = data.is_a? ::UserTeamProjectRelationship
            known_source && known_action
          end

          def build(action, source, user, data)
            meta = parse_action(action)
            actions = []
            actions << meta[:action]
            case meta[:action]
            when :created
            when :updated
            when :deleted
            end

            ::Event.new(action: ::Event::Action.action_by_name(meta[:action]), source: source, data: data.to_json, author: user)
          end
        end
      end
    end
  end
end
