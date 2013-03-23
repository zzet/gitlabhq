class Gitlab::Event::Builder::Issue < Gitlab::Event::Builder::Base
  class << self
    def can_build?(action, data)
      known_action = known_action? action, ::Issue.available_actions
      # TODO Issue can be assigned to Milestone
      # TODO Issue can be refference to Issue
      known_source = known_source? data, ::Issue.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      actions = []
      target = source

      case source.watchable_name
      when :issue

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

      when :note

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
                              source: source, data: data.attributes, author: user, target: target)
      end

      events
    end
  end
end
