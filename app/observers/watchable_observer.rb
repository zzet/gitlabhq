class WatchableObserver < ActiveRecord::Observer
  def self.observed_classes
    ActiveRecord::Base.direct_descendants
  end
end
ActiveRecord::Base.observers.insert(0, :watchable_observer) unless ActiveRecord::Base.observers.include?(:watchable_observer)
