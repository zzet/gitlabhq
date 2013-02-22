module Gitlab
  module Event
    module Builder
      class UserTeamUserRelationship < Gitlab::Event::Builder::Base
        class << self
          def can_build?(action, data)
            known_action = known_action? action, ::UserTeamUserRelationship.available_actions
            known_source = data.is_a? ::UserTeamUserRelationship
            known_source && known_action
          end

          def build(action, source, user, data)
            meta = parse_action(action)
            actions = []
            target = source
            actions << meta[:action]
            case meta[:action]
            when :created
            when :updated
            when :deleted
            end

            ::Event.new(action: meta[:action],
                        source: source, data: data.to_json, author: user, target: target)
          end
        end
      end
    end
  end
end
