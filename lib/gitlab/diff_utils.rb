module Gitlab
  module DiffUtils
    extend ActiveSupport::Concern

    included do
      def load_diff_data(oldrev, newrev, ref, project, user)
        diff_result = {}

        diff_result[:branch] = ref
        diff_result[:branch].slice!("refs/heads/")

        r = Rugged::Repository.new(project.repository.path_to_repo)

        diff_result[:before_commit] = r.lookup(oldrev)
        diff_result[:before_commit] = diff_result[:before_commit].parents.first if diff_result[:before_commit].parents.any?
        diff_result[:after_commit]  = r.lookup(newrev)
        diff_result[:commit]        = r.lookup(newrev)

        diff = r.diff(oldrev, newrev)
        diff_stat = diff.stat

        diff_result[:suppress_diff] = ((diff_stat.first > 500) || (diff_stat[1] + diff_stat[2] > 5000))

        if diff_result[:suppress_diff]
          diff_result[:commits] = []
          diff_result[:diffs]   = nil
        else
          # Temp remove Rugged with kernel bug in walker
          #walker = Rugged::Walker.new(r)
          #walker.sorting(Rugged::SORT_REVERSE)
          #walker.push(newrev)
          #walker.hide(oldrev)
          #commit_oids = walker.map {|c| c.oid}
          #walker.reset
          out, err, status = Open3.capture3("git log #{oldrev}...#{newrev} --format=\"%H\"", chdir: project.repository.path_to_repo)
          if status.success? && err.blank?
            commit_oids = out.split("\n")

            diff_result[:commits] = commit_oids.map {|coid| r.lookup(coid) }
            diff_result[:diffs]   = diff
          else
            diff_result[:commits] = []
            diff_result[:diffs]   = nil
          end
        end

        diff_result
      end
    end
  end
end
