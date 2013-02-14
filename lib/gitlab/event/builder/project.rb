module Gitlab
  module Event
    module Builder
      class Project < Gitlab::Event::Builder::Base
        def can_build?(data)
          if data.is_a? Project
          else
          end
        end

        def build(data)
        end
      end
    end
  end
end
