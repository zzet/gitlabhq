module Gitlab
  module Event
    module Builder
      class Base
        def can_build?(data)
          raise NotImplementedError
        end

        def build(data)
          raise NotImplementedError
        end
      end
    end
  end
end

Dir[File.dirname(__FILE__) << "/**/*.rb"].each {|f| require f}
