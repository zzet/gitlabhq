module Gitlab
  module Event
    module MailViewDsl
      def preview(mailer_method_name, &block)
        define_method(mailer_method_name) do
          notification = block.call

          EventNotificationMailer.send(mailer_method_name, notification)
        end
      end
    end
  end
end
