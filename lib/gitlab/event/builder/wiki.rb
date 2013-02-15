module Gitlab
  module Event
    module Builder
      class Wiki < Gitlab::Event::Builder::Base
        @avaliable_action = [:created,
                             :closed,
                             :reopened,
                             :deleted,
                             :updated
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            known_target = data[:target].is_a? ::Wiki
            known_target && known_action
          end

          def build(action, target, user, data)
            meta = parse_action(action)
            actions = []
            actions << meta[:action]

            case meta[:action]
            when :created
            when :updated
              # TODO Check
              actions << :closed if target.is_being_closed?
              actions << :reopened if target.is_being_reopened?
            when :deleted
            end

            events = []
            actions.each do |act|
              events << ::Event.new(action: ::Event::Action.action_by_name(act), target: target, data: data.to_json, author: user)
            end
          end
        end
      end
    end
  end
end
