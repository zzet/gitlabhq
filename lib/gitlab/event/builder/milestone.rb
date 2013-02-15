module Gitlab
  module Event
    module Builder
      class Milestone < Gitlab::Event::Builder::Base
        @avaliable_action = [:created,
                             :closed,
                             :reopend,
                             :deleted,
                             :updated
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            # TODO Issue can refference to milestone?
            known_target = data.is_a? ::Milestone
            known_target && known_action
          end

          def build(data)
          end
        end
      end
    end
  end
end
