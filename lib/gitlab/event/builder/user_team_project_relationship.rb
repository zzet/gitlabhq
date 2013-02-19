module Gitlab
  module Event
    module Builder
      class UserTeamProjectRelationship < Gitlab::Event::Builder::Base
        include Gitlab::Event::Action::UserTeamProjectRelationship

        class << self
          def can_build?(action, data)
            known_action = known_action? action
            known_source = data.is_a? ::UserTeamProjectRelationship
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

            ::Event.new(action: ::Event::Action.action_by_name(meta[:action]), source: source, data: data.to_json, author: user, target: target)
          end
        end
      end
    end
  end
end
