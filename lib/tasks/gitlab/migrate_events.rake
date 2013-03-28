namespace :gitlab do
  namespace :event do

    # This task will migrate all of the existing Events
    # content stored in your database into the new
    # Event system.
    desc "GITLAB | Migrate Events content from database to New event system."
    task :migrate => :environment do
      event_migrator = OldEventToNewEventMigrator.new
      event_migrator.migrate!
    end

    # This task will destroy all of the Wiki repos
    # that the Wiki migration task created. Run this
    # to clean up your environment if you experienced
    # problems during the original migration. After
    # executing this task, you can attempt the original
    # migration again.
    #
    # Notes:
    #  * This will not affect Wikis that have been created
    #    as Gollum Wikis only. It will only remove the wikis
    #    for the repositories that have old Wiki data in the
    #    dataabase.
    #  * If you have any repositories already named
    #    namespace/project.wiki that you do not wish
    #    to be removed you may want to perform a manual
    #    cleanup instead.
    desc "GITLAB | Remove the Wiki repositories created by the `gitlab:wiki:migrate` task."
    task :rollback => :environment do
      wiki_migrator = WikiToGollumMigrator.new
      wiki_migrator.rollback!
    end
  end
end
