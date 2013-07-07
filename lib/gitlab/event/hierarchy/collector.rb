class Gitlab::Event::Hierarchy::Collector
  def initialize
    @events = Gitlab::Event::Hierarchy::Storage.new
  end

  def << args
    if args.is_a? Array
      args.each { |arg| events.put arg }
    else
      events.put args
    end
  end

  def events
    @events
  end

  def reset
    @events.clear
  end
end
