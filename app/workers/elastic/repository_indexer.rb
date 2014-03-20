class Elastic::RepositoryIndexer
  include Sidekiq::Worker
  sidekiq_options queue: 'elasticsearch', retry: false, backtrace: true

  def perform(record_id, options={})
    return true # while we do not start user search on repo
    push = Push.find(record_id)
    repo = push.project.repository

    repo.index_commits(from_rev: push.revbefore, to_rev: push.revafter)

    if push.ref == push.project.default_branch
      repo.index_blobs(from_rev: push.revbefore, to_rev: push.revafter)
    end
  end
end
