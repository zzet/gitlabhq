class Push < ActiveRecord::Base
  include Watchable

  DEFAULT_COMMITS_COUNT = 20

  attr_accessible :revafter,:revbefore,
                  :ref,     :data,
                  :commits, :commits_count,
                  :project, :project_id,
                  :user,    :user_id

  belongs_to :project
  belongs_to :user

  validate :project,  presence: true
  validate :user,     presence: true
  validate :revbefore,presence: true
  validate :revafter, presence: true
  validate :ref,      presence: true

  watch do
    source watchable_name do
      from :create, to: :created
    end
  end

  serialize :data #, ActiveRecord::Serializers::MessagePackSerializer

  def refs_action?;         revafter =~ /^00000/ || revbefore =~ /^00000/; end

  def branch?;              ref =~ /^refs\/heads/; end
  def to_existing_branch?;  branch? && revbefore != "0000000000000000000000000000000000000000"; end
  def to_default_branch?;   branch? && branch_name == project.default_branch; end
  def created_branch?;      branch? && revbefore =~ /^00000/; end
  def deleted_branch?;      branch? && revafter  =~ /^00000/; end

  def tag?;                 ref =~ /^refs\/tag/; end
  def created_tag?;         tag?    && revbefore =~ /^00000/; end
  def deleted_tag?;         tag?    && revafter  =~ /^00000/; end

  def ref_name
    if tag?
      tag_name
    else
      branch_name
    end
  end

  def branch_name
    @branch_name ||= ref.gsub("refs/heads/", "")
  end

  def tag_name
    @tag_name ||= ref.gsub("refs/tags/", "")
  end

  def data(limit = DEFAULT_COMMITS_COUNT)
    @data = begin
              limit = all_commits_count unless limit.is_a?(Fixnum)
              #write_attribute(:data, load_push_data(limit))
              load_push_data(limit)
            end if @data.blank?
    @data
  end

  def commits(limit = DEFAULT_COMMITS_COUNT)
    limit = all_commits_count unless limit.is_a?(Fixnum)
    @commits ||= project.repository.commits_between(revbefore, revafter).last(limit).reverse
  end

  def commits_count(limit = DEFAULT_COMMITS_COUNT)
    limit = all_commits_count unless limit.is_a?(Fixnum)
    commits.count
  end

  def all_commits_count
    project.repository.commits_between(revbefore, revafter).count
  end

  def fill_push_data
    data(all_commits_count)
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
  #   project_id: String,
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
      # Total commits count
      commits_count = all_commits_count

      # Get latest 20 commits ASC
      push_commits_limited = commits.last(limit)

      # Hash to be passed as post_receive_data
      data = {
        before: revbefore,
        after: revafter,
        ref: ref,
        user_id: user.id,
        user_name: user.name,
        project_id: project.id,
        repository: {
          name: project.name,
          url: project.url_to_repo,
          description: project.description,
          homepage: project.web_url,
        },
        commits: [],
        total_commits_count: commits_count
      }

      # For performance purposes maximum 20 latest commits
      # will be passed as post receive hook data.
      #
      push_commits_limited.each do |commit|
        data[:commits] << {
          id: commit.id,
          message: commit.safe_message,
          timestamp: commit.committed_date.xmlschema,
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
