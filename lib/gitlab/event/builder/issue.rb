class Gitlab::Event::Builder::Issue < Gitlab::Event::Builder::Base
  class << self
    def prioritet
      2
    end

    def can_build?(action, data)
      known_action = known_action? action, ::Issue.available_actions
      # TODO Issue can be assigned to Milestone
      # TODO Issue can be refference to Issue
      known_sources = [::Issue, ::Note]
      known_source = known_sources.include? data.class
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      actions = []
      target = source

      case source
      when ::Issue

        case meta[:action]
        when :created
          actions << :assigned if source.assignee_id_changed?
        when :updated
          changes = source.changes

          actions << :assigned if source.assignee_id_changed? && changes['assignee_id'].first.nil?
          actions << :reassigned if source.assignee_id_changed? && changes['assignee_id'].first.present?
        when :closed
          actions << :closed
        when :reopened
          actions << :reopened
        when :deleted
          actions << :deleted
        end

      when ::Note

        target = source.noteable

        if target.is_a? ::Issue
          case meta[:action]
          when :created
            actions << :commented
          end
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
