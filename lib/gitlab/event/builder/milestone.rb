class Gitlab::Event::Builder::Milestone < Gitlab::Event::Builder::Base
  class << self
    def prioritet
      2
    end


    def can_build?(action, data)
      known_action = known_action? action, ::Milestone.available_actions
      # TODO Issue can refference to milestone?
      known_source = known_source? data, ::Milestone.watched_sources
      known_source && known_action
    end

    def build(action, source, user, data)
      meta = parse_action(action)
      temp_data = data.attributes
      actions = []
      target = source
      case meta[:action]
      when :created
        actions << :created
      when :updated
        temp_data[:previous_changes] = source.changes
        actions << :updated
      when :closed
        actions << :closed
      when :reopened
        actions << :reopened
      when :deleted
        actions << :deleted
      end

      events = []
      actions.each do |act|
        events << ::Event.new(action: act,
                              source: source, data: temp_data, author: user, target: target)
      end

      events
    end
  end
end
