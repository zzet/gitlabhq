module Gitlab
  module Event
    module Builder
      class Project < Gitlab::Event::Builder::Base
        @avaliable_action = [:created,
                             :deleted,
                             :updated,
                             :transfer
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            known_target = data.is_a? ::Project
            known_target && known_action
          end

          def build(action, target, user, data)
            meta = parse_action(action)
            actions = []
            actions << meta[:action]
            case meta[:action]
            when :created
            when :updated
              changes = target.changes

              # TODO puts here transfer action ckeck
              actions << :transfer if target.creator_id_changed? && target.creator_id != changes[:creator_id].first
            when :deleted
            end

            events = []
            actions.each do |act|
              events << ::Event.new(action: ::Event::Action.action_by_name(act), target: target, data: data.to_json, author: user)
            end
            events
          end
        end
      end
    end
  end
end
