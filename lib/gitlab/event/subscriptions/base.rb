module Gitlab
  module Event
    module Subscriptions
      class Base

        class << self
          def subscribe(user, action, source, target)
            action = ::Event::Action.action_by_name(action)
            subscription = nil
            case source.class.name
            when "Symbol"
              subscription = ::Event::Subscription.new(user: user, action: action, source_category: source)
            else
              unless source.is_a? Class
                subscription = ::Event::Subscription.new(user: user, action: action, source: source)
              else
                subscription = ::Event::Subscription.new(user: user, action: action, source_category: source.name.downcase.to_sym)
              end
            end
            subscription.target = target unless (target.is_a? Class)
            subscription.save
          end
        end
      end
    end
  end
end

Dir[File.dirname(__FILE__) << "/**/*.rb"].each {|f| require f}
