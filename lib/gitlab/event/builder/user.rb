module Gitlab
  module Event
    module Builder
      class User < Gitlab::Event::Builder::Base
        class << self
          def can_build?(data)
          end

          def build(data)
          end
        end
      end
    end
  end
end
