class GitPushService
  attr_accessor :project, :user, :push_data

  # This method will be called after each git update
  # and only if the provided user and project is present in GitLab.
  #
  # All callbacks for post receive action should be placed here.
  #
  # Now this method do next:
  #  1. Ensure project satellite exists
  #  2. Update merge requests
  #  3. Execute project web hooks
  #  4. Execute project services
  #  5. Create Push Event
  #
  def execute(project, user, oldrev, newrev, ref)
    @project, @user = project, user

    # Collect data for this git push
    push = Push.create(project: project, user: user, before: oldrev, after: newrev, ref: ref)
    @push_data = push.push_data

    create_push_event

    project.ensure_satellite_exists
    project.discover_default_branch
    project.repository.expire_cache

    if push.to_branch?
      project.update_merge_requests(oldrev, newrev, ref, user)
      project.execute_hooks(@push_data.dup)
      project.execute_services(@push_data.dup)
    end
  end

  # This method provide a sample data
  # generated with post_receive_data method
  # for given project
  #
  def sample_data(project, user)
    commits = project.repository.commits(project.default_branch, nil, 3)
    push = Push.new(project: project, user: user, before: commits.last.id, after: commits.first.id, ref: "refs/heads/#{project.default_branch}")
    push.push_data
  end

  protected

  def create_push_event
    OldEvent.create(
      project: project,
      action: OldEvent::PUSHED,
      data: push_data,
      author: user
    )
  end
end
