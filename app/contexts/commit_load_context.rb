class CommitLoadContext < BaseContext
  def execute
    result = {
      commit: nil,
      suppress_diff: false,
      line_notes: [],
      notes_count: 0,
      note: nil,
      status: :ok
    }

    commit = project.repository.commit(params[:id])

    if commit
      commit = CommitDecorator.decorate(commit)
      line_notes = project.notes.for_commit_id(commit.id).inline

      result[:commit] = commit
      result[:note] = project.build_commit_note(commit)
      result[:line_notes] = line_notes
      result[:notes_count] = project.notes.for_commit_id(commit.id).count

      begin
        result[:suppress_diff] = true if commit.diffs.size > Commit::DIFF_SAFE_SIZE && !params[:force_show_diff]
        # TODO: Rewrite it after merging upstream
        lines_count = commit.diffs.inject(0) { |sum, diff| diff.diff.lines.count }
        result[:suppress_diff] ||= lines_count > Commit::DIFF_SAFE_LINES_COUNT
      rescue Grit::Git::GitTimeout
        result[:suppress_diff] = true
        result[:status] = :huge_commit
      end
    end

    result
  end
end
