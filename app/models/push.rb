# == Schema Information
#
# Table name: pushes
#
#  id            :integer          not null, primary key
#  ref           :string(255)
#  revbefore     :string(255)
#  revafter      :string(255)
#  data          :text
#  project_id    :integer
#  user_id       :integer
#  commits_count :integer
#  created_at    :datetime
#  updated_at    :datetime
#

class Push < ActiveRecord::Base
  include Watchable

  DEFAULT_COMMITS_COUNT = 20

  attr_accessible :revafter, :revbefore, :ref, :data, :commits_count,
                  :project, :project_id, :user, :user_id

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

  # Prepared push data for sending to external services
  serialize :data #, ActiveRecord::Serializers::MessagePackSerializer

  def refs_action?
    revafter == "0000000000000000000000000000000000000000" ||
      revbefore == "0000000000000000000000000000000000000000"
  end

  def branch?;              (ref =~ /^refs\/heads/).present?; end
  def to_existing_branch?;  branch? && revbefore != "0000000000000000000000000000000000000000"; end
  def to_default_branch?;   branch? && branch_name == project.default_branch; end
  def created_branch?;      branch? && revbefore == "0000000000000000000000000000000000000000"; end
  def deleted_branch?;      branch? && revafter  == "0000000000000000000000000000000000000000"; end

  def tag?;                 (ref =~ /^refs\/tag/).present?; end
  def created_tag?;         tag?    && revbefore == "0000000000000000000000000000000000000000"; end
  def deleted_tag?;         tag?    && revafter  == "0000000000000000000000000000000000000000"; end

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

  def fill_push_data
    write_attribute(:data, load_push_data(DEFAULT_COMMITS_COUNT))
  end

  def commits(limit = DEFAULT_COMMITS_COUNT)
    # select all committs if symbol :all received
    limit = commits_count unless limit.is_a?(Fixnum)

    load_commits_from_repository(limit)
  end

  def commits_count
    @commits_count ||= begin
                         if data.present? && data[:total_commits_count]
                           data[:total_commits_count]
                         else
                           load_commits_from_repository.count
                         end
                       end
  end

  def load_commits_from_repository(limit = :all)
    @commits_from_repository ||= project.repository.commits_between(revbefore, revafter)
    limit.is_a?(Fixnum) ? @commits_from_repository.first(limit) : @commits_from_repository
  end

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
      # Hash to be passed as post_receive_data
      data = {
        ref: ref,
        before: revbefore,
        after: revafter,
        user_id: user.id,
        user_name: user.name,
        project_id: project_id,
        project_name_with_namespace: project.name_with_namespace,
        repository: {
          namespace: project.namespace.name,
          name: project.name,
          url: project.url_to_repo,
          description: project.description,
          homepage: project.web_url,
        }
      }

      unless tag?
        # Total commits count
        data[:total_commits_count] = commits_count

        # Get latest 20 commits ASC
        push_commits_limited = commits.last(limit)

        data[:commits] = []

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
      end

      data
    rescue Exception => ex
      raise RuntimeError, "Can't process push recive data. \r\n#{ex.message}\r\n#{ex.backtrace.join("\r\n")}"
    end
  end
end
