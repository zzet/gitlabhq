module Gitlab
  module Event
    module Builder
      class MergeRequest < Gitlab::Event::Builder::Base
        include Gitlab::Event::Action::MergeRequest

        class << self
          def can_build?(action, data)
            known_action = known_action? action
            # TODO Issue can be refference to MergeRequest
            known_source = data.is_a? ::MergeRequest
            known_source && known_action
          end

          def build(action, source, user, data)
            meta = parse_action(action)
            actions = []
            actions << meta[:action]
            case meta[:action]
            when :created
              actions << :assigned if source.assignee_id_changed?
            when :updated
              changes = source.changes

              actions << :assigned if source.assignee_id_changed? && changes['assignee_id'].first.nil?
              actions << :reassigned if source.assignee_id_changed? && changes['assignee_id'].first.present?

              actions << :closed if source.is_being_closed?
              actions << :reopened if source.is_being_reopened?
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
