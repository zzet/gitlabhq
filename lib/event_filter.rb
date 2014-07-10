class EventFilter
  attr_accessor :params

  class << self
    def default_filter
      %w{ push issues merge_requests team}
    end

    def push
      'push'
    end

    def merged
      'merged'
    end

    def comments
      'comments'
    end

    def team
      'team'
    end

    def group
      'group'
    end

    def favourite
      'favourite'
    end
  end

  def initialize params
    @params = if params
                params.dup
              else
                []#EventFilter.default_filter
              end
  end

  def apply_filter events
    return events unless params.present?

    table = Event.arel_table

    filter = params.dup

    actions = []
    actions << :pushed if filter.include? 'push'
    actions += Event::Action::MERGE_REQUESTS if filter.include? 'merged'
    actions += Event::Action::COMMENTS if filter.include? 'comments'

    target_types = []
    target_types << Team if filter.include? 'team'
    target_types << Group if filter.include? 'group'

    action_cond = table[:action].in(actions)
    target_cond = table[:target_type].in(target_types)

    events = if actions.any? && target_types.any?
               events.where(action_cond.or(target_cond))
             elsif actions.any? && target_types.empty?
               events.where(action_cond)
             elsif actions.blank? && target_types.any?
               events.where(target_cond)
             else
               events
             end
    events
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

  def active? key
    params.include? key
  end
end
