class EventHierarchyWorker
  class << self
    def call(name, started, finished, unique_id, data)
      collector << { name: name, data: data }
    end

    def events
      collector.events
    end

    def reset
      collector.reset
    end

    def collector
      @collector ||= Gitlab::Event::Hierarchy::Collector.new
    end
  end
end

