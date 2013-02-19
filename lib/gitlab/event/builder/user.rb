module Gitlab
  module Event
    module Builder
      class User < Gitlab::Event::Builder::Base
        include Gitlab::Event::Action::User

        class << self
          def can_build?(action, data)
            known_action = known_action? action
            known_sources = [::User, ::UserTeamUserRelationship, ::UsersProject, ::Key]
            known_source = known_sources.include? data.class
            known_source && known_action
          end

          def build(action, source, user, data)
            meta = parse_action(action)

            actions = []

            case source
            when ::User
              target = source

              actions << meta[:action]

              case meta[:action]
              when :created
              when :updated
              when :deleted
              end

            when ::Key
              target = source.user

              case meta[:action]
              when :created
                actions << :added
              when :updated
                actions << :updated
              when :deleted
                actions << :deleted
              end
            when ::UsersProject
              target = source.user

              case meta[:action]
              when :created
                actions << :joined
              when :updated
                actions << :updated
              when :deleted
                actions << :left
              end
            when ::UserTeamUserRelationship
              target = source.user

              case meta[:action]
              when :created
                actions << :joined
              when :updated
                actions << :updated
              when :deleted
                actions << :left
              end
            end

            events = []

            actions.each do |act|
              events << ::Event.new(action: ::Event::Action.action_by_name(act),
                                    source: source, data: data.to_json, author: user, target: target)
            end

            events
          end
        end
      end
    end
  end
end
