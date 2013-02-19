module Gitlab
  module Event
    module Builder
      class Group < Gitlab::Event::Builder::Base
        include Gitlab::Event::Action::Group

        class << self
          def can_build?(action, data)
            known_action = known_action? action
            known_sources = [::Group, ::Project]
            known_source = known_sources.include? data.class
            known_source && known_action
          end

          def build(action, source, user, data)
            meta = parse_action(action)

            target = source

            actions = []

            case source
            when ::Group
              actions << meta[:action]

              case meta[:action]
              when :created
              when :updated
                changes = source.changes

                actions << :transfer if source.owner_id_changed? && source.owner_id != changes[:owner_id].first
              when :deleted
              end

            when ::Project
              # TODO. refactoring
              target = source.group if source.group.present?

              case meta[:action]
              when :created
                actions << :added if source.group == target
              when :updated
                changes = source.changes

                # TODO. refactor
                actions << :added if source.namespace_id_changed? && source.namespace_id != changes[:namespace_id].first && source.namespace == target
                actions << :transfer if source.namespace_id_changed? && source.namespace_id != changes[:namespace_id].first && Group.find_by_id(changes["namespace_id"]).present?
              when :deleted
                actions << :deleted
              end
            end

            events = []

            actions.each do |act|
              events << ::Event.new(action: ::Event::Action.action_by_name(act),
                                    source_id: source.id, source_type: source.class.name,
                                    target_id: target.id, target_type: target.class.name,
                                    data: data.to_json, author: user)
            end

            events
          end
        end
      end
    end
  end
end
