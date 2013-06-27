class Push < ActiveRecord::Base
  include Watchable

  attr_accessible :after, :before,
                  :commits_count, :data,
                  :project, :user,
                  :project_id, :ref, :user_id

  belongs_to :project
  belongs_to :user
  has_many :commits

  validate :project, presence: true
  validate :user,    presence: true
  validate :before,  presence: true
  validate :after,   presence: true

  actions_to_watch [:pushed, :created_branch, :deleted_branch, :created_tag, :deleted_tag]
  actions_sources [watchable_name]
  available_in_activity_feed true, actions: [:pushed, :created_branch, :deleted_branch, :created_tag, :deleted_tag]

  def to_branch?
    ref =~ /^refs\/heads/ || before =~ /^00000/
  end

  def created_branch?
    ref =~ /^refs\/heads/ && before =~ /^00000/
  end

  def deleted_branch?
    ref =~ /^refs\/heads/ && after  =~ /^00000/
  end

  def created_tag?
    ref =~ /^refs\/tag/   && before =~ /^00000/
  end

  def deleted_tag?
    ref =~ /^refs\/tag/   && after  =~ /^00000/
  end

  def push_data(limit = 20)
    data ||= load_push_data(limit)
  end

  protected

  # Produce a hash of post-receive data
  #
  # data = {
  #   before: String,
  #   after: String,
  #   ref: String,
  #   user_id: String,
  #   user_name: String,
  #   repository: {
  #     name: String,
  #     url: String,
  #     description: String,
  #     homepage: String,
  #   },
  #   commits: Array,
  #   total_commits_count: Fixnum
  # }
  #
  def load_push_data(limit)
    begin
      push_commits = project.repository.commits_between(before, after)

      # Total commits count
      push_commits_count = push_commits.size

      # Get latest 20 commits ASC
      push_commits_limited = push_commits.last(limit)

      # Hash to be passed as post_receive_data
      data = {
        before: before,
        after: after,
        ref: ref,
        user_id: user.id,
        user_name: user.name,
        repository: {
        name: project.name,
        url: project.url_to_repo,
        description: project.description,
        homepage: project.web_url,
      },
      commits: [],
      total_commits_count: push_commits_count
      }

      # For performance purposes maximum 20 latest commits
      # will be passed as post receive hook data.
      #
      push_commits_limited.each do |commit|
        data[:commits] << {
          id: commit.id,
          message: commit.safe_message,
          timestamp: commit.date.xmlschema,
          url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/commit/#{commit.id}",
          author: {
            name: commit.author_name,
            email: commit.author_email
          }
        }
      end

      data
    rescue Exception => ex
      raise RuntimeError, "Can't process push recive data. \r\n#{ex.message}\r\n#{ex.backtrace.join("\r\n")}"
    end
  end
end
