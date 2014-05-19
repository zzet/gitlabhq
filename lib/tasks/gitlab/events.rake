namespace :events do
  desc('Extract commits from git for new events.')
  task extract_commits: :environment do
    Migration::Event::CachePush.migrate
  end

  desc('Add first_domain, second_domain for relational events.')
  task domain_for_relation_events: :environment do
    Migration::Event::DomainForRelationEvent.migrate
  end
end
