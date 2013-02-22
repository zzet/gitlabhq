module Gitlab
  module Event
    module Builder
      class UserTeam < Gitlab::Event::Builder::Base
        class << self
          def can_build?(action, data)
            known_action = known_action? action, ::UserTeam.available_actions
            known_sources = [::UserTeam, ::UserTeamProjectRelationship, ::UserTeamUserRelationship]
            known_source = known_sources.include? data.class
            known_source && known_action
          end

          def build(action, source, user, data)
            meta = parse_action(action)
            actions = []

            case source
            when ::UserTeam
              target = source
              actions << meta[:action]

              case meta[:action]
              when :created
              when :updated
              when :deleted
              end

            when ::UserTeamUserRelationship
              target = source.user_team

              case meta[:action]
              when :created
                actions << :joined
              when :updated
                actions << :updated
              when :deleted
                actions << :left
              end

            when ::UserTeamProjectRelationship
              target = source.user_team

              case meta[:action]
              when :created
                actions << :assigned
              when :updated
                actions << :updated
              when :deleted
                actions << :reassigned
              end

            end
            events = []
            actions.each do |act|
              events << ::Event.new(action: act,
                                    source: source, data: data.to_json, author: user, target: target)
            end
            events
          end
        end
      end
    end
  end
end
