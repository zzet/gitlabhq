class ActivityFeed
  include ActiveModel::Conversion
  include StaticModel
  extend ActiveModel::Naming

  @@sources = []
  @@sources_actions = {}

  def initialize(user)
    @user = user
  end

  class << self
    def register_sources(sources)
      @@sources << sources
    end

    def register_actions(source, actions)
      @@sources_actions[source] = actions
    end

    def sources
      @@sources
    end

    def actions(source)
      @@sources_actions[source]
    end

    def events(events_relation, user = nil)
      query_condition = nil
      query_params = []

      event = Event.arel_table

      sources.each do |source|
        source_param = source.to_s.camelize
        actions_param = actions(source)
        query_param = event[:source_type].eq(source_param).and(event[:action].in(actions_param))
        if user.respond_to? "authorized_#{source.to_s}s"
          query_param = query_param.and(event[:source_id].in(user.send("authorized_#{source.to_s}s").pluck(:id)))
        end
        query_params << query_param
      end

      query_condition = query_params.inject{|sc, q| sc.or(q) } unless query_params.blank?

      query_condition.nil? ? events_relation.scoped : events_relation.where(query_condition)
    end
  end

  def events
    prepared_events = Event.recent
    self.class.events(prepared_events, @user)
  end


end
