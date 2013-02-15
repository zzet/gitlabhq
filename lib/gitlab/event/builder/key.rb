module Gitlab
  module Event
    module Builder
      class Key < Gitlab::Event::Builder::Base

        @avaliable_action = [:created,
                             :deleted,
                             :updated
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            known_target = data.is_a? ::Key
            known_target && known_action
          end

          def build(data)
          end
        end
      end
    end
  end
end
