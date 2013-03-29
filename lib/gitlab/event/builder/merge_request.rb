class Gitlab::Event::Builder::MergeRequest < Gitlab::Event::Builder::Base
  class << self

    def can_build?(action, data)
      known_action = known_action? action, ::MergeRequest.available_actions
      # TODO Issue can be refference to MergeRequest
      known_source = known_source? data, ::MergeRequest.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)

      actions = []

      case source.watchable_name
      when :merge_request
        target = source

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

        if target.is_a? ::MergeRequest
          case meta[:action]
          when :created
            actions << :added
          when :updated
          when :deleted
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
