class EventFilter
  attr_accessor :params

  class << self
    ActivityFeed.sources.each do |source|
      define_method(source) { source.to_s }
    end

    def default_filter
      ActivityFeed.sources
    end
  end

  def initialize params
    @params = if params
                params.dup.map { |i| i.to_sym }
              else
                ActivityFeed.sources
              end
  end

  def active_options
    @params
  end

  def default_options
    self.class.default_filter
  end

  def prepare_filter
    exclude_list = []
    default_options.each do |source|
      exclude_list << source unless active_options.include? source
    end
    exclude_list
  end

  def active? key
    active_options.include? key
  end

  def apply_filter events
    return events unless params.present?

    filter = params.dup

    actions = []
    actions << OldEvent::PUSHED if filter.include? 'push'
    actions << OldEvent::MERGED if filter.include? 'merged'

    if filter.include? 'team'
      actions << OldEvent::JOINED
      actions << OldEvent::LEFT
    end

    actions << OldEvent::COMMENTED if filter.include? 'comments'

    events = events.where(action: actions)
  end

  def options key
    filter = params.dup

    if filter.include? key
      filter.delete key
    else
      filter << key
    end

    filter
  end

end
