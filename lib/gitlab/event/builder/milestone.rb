module Gitlab
  module Event
    module Builder
      class Milestone < Gitlab::Event::Builder::Base
        class << self
          def can_build?(action, data)
            known_action = known_action? action, ::Milestone.available_actions
            # TODO Issue can refference to milestone?
            known_source = data.is_a? ::Milestone
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
              #TODO. Check, if Only closed/reopened - not make :updated event
            when :closed
            when :reopened
            when :deleted
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
