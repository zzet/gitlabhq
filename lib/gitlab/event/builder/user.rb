module Gitlab
  module Event
    module Builder
      class User < Gitlab::Event::Builder::Base
        @avaliable_action = [:created,  # +
                             :deleted,  # +
                             :updated,  # +
                             :joined,   # - # Join to ptoject or team
                             :left,     # - # Left from project or team
                             :transfer, # - # Change permission on team or project
                             :added     # - # Add admin permission
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            # TODO Add support to UsersProject models and UserTeam*Relationships
            known_target = data.is_a? ::User
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

            events = []
            actions.each do |act|
              events << ::Event.new(action: ::Event::Action.action_by_name(act), target: target, data: data.to_json, author: user)
            end
            events
          end
        end
      end
    end
  end
end
