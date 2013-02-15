module Gitlab
  module Event
    module Builder
      class MergeRequest < Gitlab::Event::Builder::Base

        @avaliable_action = [:created,
                             :closed,
                             :reopened,
                             :deleted,
                             :updated,
                             :assigned,
                             :reassigned,
                             :commented,
                             :merged
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            # TODO Issue can be refference to MergeRequest
            known_target = data.is_a? ::MergeRequest
            known_target && known_action
          end

          def build(data)
          end
        end
      end
    end
  end
end
