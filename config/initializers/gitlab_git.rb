# Workaround for https://github.com/gitlabhq/gitlab_git/pull/19/
module Gitlab
  module Git
    class Diff
      def self.between(repo, head, base, *paths)
        # Only show what is new in the source branch compared to the target branch, not the other way around.
        # The linex below with merge_base is equivalent to diff with three dots (git diff branch1...branch2)
        # From the git documentation: "git diff A...B" is equivalent to "git diff $(git-merge-base A B) B"
        common_commit = repo.merge_base_commit(head, base)

        repo.diff(common_commit, head, *paths).map do |diff|
          Gitlab::Git::Diff.new(diff)
        end
      rescue Grit::Git::GitTimeout
        [Gitlab::Git::Diff::BROKEN_DIFF]
      end
    end

    class Repository
      def diff(from, to, *paths)
        grit.diff(from, to, *paths)
      end
    end

    class Compare
      def initialize(repository, from, to, limit = 100)
        @commits, @diffs = [], []
        @commit = nil
        @same = false
        @limit = limit
        @repository = repository

        return unless from && to

        @base = Gitlab::Git::Commit.find(repository, from.try(:strip))
        @head = Gitlab::Git::Commit.find(repository, to.try(:strip))

        return unless @base && @head

        if @base.id == @head.id
          @same = true
          return
        end

        @commit = @head
        @commits = Gitlab::Git::Commit.between(repository, @base.id, @head.id)
      end

      def diffs(paths = nil)
        return [] if @commits.size > @limit && paths.blank?
        Gitlab::Git::Diff.between(@repository, @head.id, @base.id, *paths) rescue []
      end
    end

  end
end


