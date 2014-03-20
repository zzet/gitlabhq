module RepositoriesSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Git::Repository

    def repository_id
      project.id
    end

    def self.import
      Repository.__elasticsearch__.create_index! force: true

      Project.find_each do |project|
        if project.repository.exists? && !project.repository.empty?
          begin
            project.repository.index_commits
          rescue
          end
          begin
            project.repository.index_blobs
          rescue
          end
        end
      end
    end
  end
end
