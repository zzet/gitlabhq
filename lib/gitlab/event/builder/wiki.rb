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
            known_source = data.is_a? ::Wiki
            known_source && known_action
          end

          def build(action, source, user, data)
            meta = parse_action(action)
            actions = []
            actions << meta[:action]

            case meta[:action]
            when :created
            when :updated
              # TODO Check
              #actions << :closed if source.is_being_closed?
              #actions << :reopened if source.is_being_reopened?
            when :deleted
            end

            events = []
            actions.each do |act|
              events << ::Event.new(action: ::Event::Action.action_by_name(act), source: source, data: data.to_json, author: user)
            end
            events
          end
        end
      end
    end
  end
end
