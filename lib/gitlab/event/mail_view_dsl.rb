module Gitlab
  module Event
    module MailViewDsl
      def preview(mailer_method_name, notification_name = nil, &block)
        define_method(mailer_method_name) do
          ActiveRecord::Base.observers.disable :all

          if Gitlab::Event::SeedBuilder.respond_to?(notification_name.to_sym)
            notification = Gitlab::Event::SeedBuilder.send(notification_name.to_sym)
          else
            notification = block.call
          end

          EventNotificationMailer.send(mailer_method_name, notification)
        end
      end
    end
  end
end
