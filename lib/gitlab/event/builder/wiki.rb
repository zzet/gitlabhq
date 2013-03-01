module Gitlab
  module Event
    module Builder
      class Push < Gitlab::Event::Builder::Base
        class << self
          def can_build?(action, data)
            known_action = known_action? action, [:pushed]
            known_source = data.is_a? ::Hash
            known_source && known_action
          end

          def build(action, source, user, data)
            meta = parse_action(action)
            actions = []

            # TODO. Add project_id to hash
            target = ::Project.find_by_name(data[:project_id])
            actions << meta[:action]

            case meta[:action]
            when :created
            when :updated
            when :pushed

            when :deleted
            end

            events = []

            actions.each do |act|
              events << ::Event.new(action: act, source_type: source, data: data.to_json, author: user, target: target)
            end

            events
          end
        end
      end
    end
  end
end
