module Gitlab
  module Event
    module Builder
      class Wiki < Gitlab::Event::Builder::Base
        include Gitlab::Event::Action::Wiki

        class << self
          def can_build?(action, data)
            known_action = known_action? action
            known_source = data.is_a? ::Wiki
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
            when :closed
            when :reopened
            when :deleted
            end

            events = []
            actions.each do |act|
              events << ::Event.new(action: ::Event::Action.action_by_name(act), source: source, data: data.to_json, author: user, target: target)
            end
            events
          end
        end
      end
    end
  end
end
