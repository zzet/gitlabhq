class Migration::Event::DomainForRelationEvent
  def self.migrate
    source_types = %w(UsersProject UsersGroup TeamGroupRelationship TeamUserRelationship TeamProjectRelationship)
    events = Event.where(parent_event_id: nil).where('source_type = target_type').where(source_type: source_types)

    events.find_each do |event|
      source_type = event.source_type
      data = event.data

      case source_type
        when 'UsersProject'
          event.first_domain_id = data['user_id']
          event.first_domain_type = 'User'

          event.second_domain_id = data['project_id']
          event.second_domain_type = 'Project'
        when 'UsersGroup'
          event.first_domain_id = data['user_id']
          event.first_domain_type = 'User'

          event.second_domain_id = data['group_id']
          event.second_domain_type = 'Group'
        when 'TeamGroupRelationship'
          event.first_domain_id = data['team_id']
          event.first_domain_type = 'Team'

          event.second_domain_id = data['group_id']
          event.second_domain_type = 'Group'
        when 'TeamUserRelationship'
          event.first_domain_id = data['team_id']
          event.first_domain_type = 'Team'

          event.second_domain_id = data['user_id']
          event.second_domain_type = 'User'
        when 'TeamProjectRelationship'
          event.first_domain_id = data['team_id']
          event.first_domain_type = 'Team'

          event.second_domain_id = data['project_id']
          event.second_domain_type = 'Project'
        else
          raise 'something wrong'
      end

      event.save(validate: false)
    end

  end
end
