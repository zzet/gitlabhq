class Gitlab::Event::Notification::Factory

  class << self

    def create_notifications(event)
      if can_create_notifications?(event)
        creator = creator_for(event)

        creator.create(event)
      end
    end

    # Creator can be specifed for any Event
    # Gitlab::Event::Notification::Creator::Custom
    # Where Custom is a:
    # 1) Event.target
    # 2) Event.target -> Event.action
    def creator_for(event)
      creator = source_with_action_creator(event)
      creator ||= source_creator(event)
      creator ||= default_creator(event)

      creator
    end

    private

    def can_create_notifications?(event)
      true
      # Chack event.deleted_related? || event.deleted_self? || event.push_event? || event.full?
    end

    def source_with_action_creator(event)
      klass = "Gitlab::Event::Notification::Creator::#{event.target_type}::#{event.source_type}#{event.action.camelize}"
      klass = klass.constantize

      klass.new
    rescue NameError
      nil
    end

    def source_creator(event)
      klass = "Gitlab::Event::Notification::Creator::#{event.target_type}"
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
