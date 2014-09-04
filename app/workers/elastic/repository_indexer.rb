class Elastic::RepositoryIndexer
  @queue = :elasticsearch

  def self.perform(record_id, options={})
    push = Push.find(record_id)
    repo = push.project.repository

    repo.index_commits(from_rev: push.revbefore, to_rev: push.revafter)

    if push.ref.name == push.project.default_branch
      repo.index_blobs(from_rev: push.revbefore, to_rev: push.revafter)
    end
  end
end
