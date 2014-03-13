namespace :undev do
  namespace :elastic do
    desc "Indexing repositories"
    task :index_repository do
      Repository.import
    end

    desc "Index DB"
    task :index_custom do
      [Project, Group, Team, User, Issue, MergeRequest].each do |klass|
        klass.__elasticsearch__.create_index! force: true
        klass.import
      end
    end
  end
end
