class GitPushService
  attr_accessor :current_user, :project, :params,
    :oldrev, :newrev, :ref,
    :push_data, :push_commits

  def initialize(user, project, oldrev = nil, newrev = nil, ref = nil, params = {})
    @current_user = user
    @project = project
    @oldrev = oldrev
    @newrev = newrev
    @ref = ref
    @params = params.dup
  end

  # This method will be called after each git update
  # and only if the provided user and project is present in GitLab.
  #
  # All callbacks for post receive action should be placed here.
  #
  # Next, this method:
  #  1. Creates the push event
  #  2. Ensures that the project satellite exists
  #  3. Updates merge requests
  #  4. Recognizes cross-references from commit messages
  #  5. Executes the project's web hooks
  #  6. Executes the project's services
  #
  def execute
    if oldrev.nil? || newrev.nil? || ref.nil?
      raise "Incorrect data"
    end

    RequestStore.store[:current_user] = current_user # unless current_user.present?

    push = Push.new(project: project, user: current_user, revbefore: oldrev, revafter: newrev, ref: ref)
    push.fill_push_data
    push.save

    @push_data    = push.data.dup
    @push_commits = push.commits.dup

    # For issue Feature #43932 add categories list to hook json
    @push_data[:repository][:categories] = project.categories.map {|c| c.name }

    create_push_event

    project.ensure_satellite_exists
    project.repository.expire_cache
    project.update_repository_size

    if push.to_existing_branch?
      project.update_merge_requests(oldrev, newrev, ref, @current_user)
      process_commit_messages(push)
    end

    if push.tag?
      project.execute_hooks(@push_data.dup, :tag_push_hooks)
    else
      Resque.enqueue(Elastic::RepositoryIndexer, push.id)
      project.execute_hooks(@push_data.dup, :push_hooks)
    end

    project.execute_services(@push_data.dup)

    if push.created_branch?
      # Re-find the pushed commits.
      if push.to_default_branch?
        # Initial push to the default branch. Take the full history of that branch as "newly pushed".
        @push_commits = project.repository.commits(newrev)
      else
        # Use the pushed commits that aren't reachable by the default branch
        # as a heuristic. This may include more commits than are actually pushed, but
        # that shouldn't matter because we check for existing cross-references later.
        @push_commits = project.repository.commits_between(project.default_branch, newrev)
      end

      process_commit_messages(push)
    end
  end

  # This method provide a sample data
  # generated with post_receive_data method
  # for given project
  #
  def sample_data
    @project, @user = project, current_user
    @push_commits = project.repository.commits(project.default_branch, nil, 3)
    push = Push.new(project: project, user: @user, revbefore: @push_commits.last.id, revafter: @push_commits.first.id, ref: "refs/heads/#{project.default_branch}")
    push.fill_push_data
    push.data
  end

  protected

  def create_push_event
    OldEvent.create!(
      project: project,
      action: OldEvent::PUSHED,
      data: @push_data,
      author_id: @push_data[:user_id]
    )

  end

  # Extract any GFM references from the pushed commit messages. If the configured issue-closing regex is matched,
  # close the referenced Issue. Create cross-reference Notes corresponding to any other referenced Mentionables.
  def process_commit_messages(push)
    is_default_branch = push.to_default_branch?

    @push_commits.each do |commit|
      # Close issues if these commits were pushed to the project's default branch and the commit message matches the
      # closing regex. Exclude any mentioned Issues from cross-referencing even if the commits are being pushed to
      # a different branch.
      issues_to_close = commit.closes_issues(project)
      author = commit_user(commit)

      if !issues_to_close.empty? && is_default_branch
        RequestStore.store[:current_user] = author
        RequestStore.store[:current_commit] = commit

        issues_to_close.each { |i| i.close && i.save }
        # FIXME. Add Issue close service
        #issues_to_close.each do |issue|
        #Issues::CloseService.new(project, author, {}).execute(issue, commit)
        #end
      end

      # Create cross-reference notes for any other references. Omit any issues that were referenced in an
      # issue-closing phrase, or have already been mentioned from this commit (probably from this commit
      # being pushed to a different branch).
      refs = commit.references(project) - issues_to_close
      refs.reject! { |r| commit.has_mentioned?(r) }
      refs.each do |r|
        Note.create_cross_reference_note(r, commit, author, project)
      end
    end
  end

  def commit_user commit
    User.find_for_commit(commit.author_email, commit.author_name) || current_user
  end
end
