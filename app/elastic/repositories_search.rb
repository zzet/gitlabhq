module RepositoriesSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Git::Repository

    def repository_id
      project.id
    end
  end
end
