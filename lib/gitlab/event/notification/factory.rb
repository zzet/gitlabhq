class Gitlab::Event::Notification::Factory

  class << self

    def create_notifications(event)
      if can_create_notifications?(event)
        creator = creator_for(event)

        creator.create(event)
      end
    end

    def can_create_notifications?(event)
      event.deleted_related? || event.deleted_self? || event.push_event? || event.full?
      # (event.target || event.action.to_sym == :deleted) && ((::Event::Action.push_action?(event.action)) || event.source_type)
    end

    def creator_for(event)
      creator = source_with_action_creator(event)
      creator ||= source_creator(event)
      creator ||= default_creator(event)

      creator
    end

    private

    def source_with_action_creator(event)
      klass = "Gitlab::Event::Notification::Creator::#{event.source_type.to_s}#{event.action.camelize}"
      klass = klass.constantize

      klass.new
    rescue NameError
      nil
    end

    def source_creator(event)
      klass = "Gitlab::Event::Notification::Creator::#{event.source_type.to_s}"
      klass = klass.constantize

      klass.new
    rescue NameError
      nil
    end

    def default_creator(event)
      Gitlab::Event::Notification::Creator::Default.new
    end
  end
end
