# == Schema Information
#
# Table name: events
#
#  id                 :integer          not null, primary key
#  author_id          :integer
#  action             :string(255)
#  source_id          :integer
#  source_type        :string(255)
#  target_id          :integer
#  target_type        :string(255)
#  data               :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  parent_event_id    :integer
#  system_action      :string(255)
#  first_domain_id    :integer
#  first_domain_type  :string(255)
#  second_domain_id   :integer
#  second_domain_type :string(255)
#  uniq_hash          :string(255)
#

class Event < ActiveRecord::Base
  include Actionable

  attr_accessible :action,    :system_action, :data,
                  :source_id, :source_type, :source,
                  :target_id, :target_type, :target,
                  :author_id, :author, :uniq_hash

  belongs_to :target, polymorphic: true
  belongs_to :source, polymorphic: true

  belongs_to :first_domain, polymorphic: true
  belongs_to :second_domain, polymorphic: true

  belongs_to :author,       class_name: User
  belongs_to :parent_event, class_name: Event

  has_many :notifications,  dependent: :destroy,     class_name: Event::Subscription::Notification
  has_many :subscriptions,  dependent: :destroy,     class_name: Event::Subscription, through: :notifications
  has_many :subscribers,    through: :subscriptions, class_name: User

  validates :author,  presence: true
  validates :source,  presence: true

  # cached source
  # TODO rename to cached_source for example
  serialize :data, JSON

  # Scopes
  scope :with_source, ->(source) { where(source_id: source, source_type: source.class.name) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_target, ->(target) { where(target_id: target, target_type: target.class.name) }
  scope :with_push, -> { where(source_type: Push) }
  scope :by_user,     ->(user)   { where(author_id: user.id) }

  scope :for_main_dashboard, -> (user) do
    table = self.arel_table

    projects_ids = user.authorized_projects.pluck(:id)
    groups_ids = user.authorized_groups.pluck(:id)
    teams_ids = user.only_authorized_teams_ids

    project_related = [Push, Note, MergeRequest]
    where(
        table[:parent_event_id].eq(nil).and(
            table[:target_type].eq(Project).and(table[:target_id].in(projects_ids))
            .or(table[:target_type].eq(Group).and(table[:target_id].in(groups_ids)))
            .or(table[:target_type].eq(Team).and(table[:target_id].in(teams_ids)))
            .or(table[:first_domain_type].eq(Project).and(table[:first_domain_id].in(projects_ids)))
            .or(table[:second_domain_type].eq(Project).and(table[:second_domain_id].in(projects_ids)))
            .or(table[:first_domain_type].eq(Group).and(table[:first_domain_id].in(groups_ids)))
            .or(table[:second_domain_type].eq(Group).and(table[:second_domain_id].in(groups_ids)))
            .or(table[:first_domain_type].eq(Team).and(table[:first_domain_id].in(teams_ids)))
            .or(table[:second_domain_type].eq(Team).and(table[:second_domain_id].in(teams_ids)))
        )
        .or(table[:target_type].eq(Project).and(table[:target_id]
              .in(projects_ids)).and(table[:source_type].in(project_related)))
    )

  end

  #TODO split method
  scope :for_dashboard, -> (target) do
    table = self.arel_table
    q = joins('LEFT JOIN events as e2 on events.parent_event_id = e2.id')

    case target.class.name
      when 'Group', 'Team'
        projects_ids = target.projects.pluck(:id)

        q = q.where(
            (table[:target_type].eq(target.class.name).and(table[:target_id].eq(target.id)))
            .or(
                table[:target_type].eq('Project')
                .and(table[:target_id].in(projects_ids))
                .and(table[:source_type].not_eq(TeamProjectRelationship))
            )
        )
      when 'User'
        projects_ids = target.authorized_projects.pluck(:id)

        q = q.where(
            (table[:target_type].eq(target.class.name).and(table[:target_id].eq(target.id)))
            .or(
                table[:target_type].eq('Project')
                .and(table[:target_id].in(projects_ids))
                .and(table[:author_id].eq(target.id))
            )
        )
      else
        q = q.where(target_type: target.class, target_id: target.id)
    end

    q.where('e2.target_type IS NULL or events.target_type <> e2.target_type')
  end

  def deleted_event?
    if system_action.present?
      system_action.to_sym == :destroy
    end
  end

  def push_event?
    return false unless Event::Action.push_action?(action)
    return true if data["repository"]
  end

  def deleted_related?
    deleted_event? && target && source_type.blank?
  end

  def deleted_self?
    deleted_event? && target.blank?
  end

  def full?
    source.present? && target.present?
  end

  #TODO implement
  def body?
    true
  end

  def tag?
    data["ref"]["refs/tags"]
  end

  def push_action_name
    if new_ref?
      "pushed new"
    elsif rm_ref?
      "deleted"
    else
      "pushed to"
    end
  end

  def new_ref?
    commit_from =~ /^00000/
  end

  def rm_ref?
    commit_to =~ /^00000/
  end

  def md_ref?
    !(rm_ref? || new_ref?)
  end

  def push_with_commits?
    md_ref? && commits.any? && commit_from && commit_to
  end

  def commits
    (data.try(:[], 'data').try(:[], 'commits') || []).reverse
  end

  def commits_count
    data['data']['total_commits_count']
  end

  def commit_from
    data["revbefore"]
  end

  def commit_to
    data["revafter"]
  end

  def ref_type
    tag? ? "tag" : "branch"
  end

  def ref_name
    if tag?
      tag_name
    else
      branch_name
    end
  end

  def branch_name
    @branch_name ||= data["ref"].gsub("refs/heads/", "")
  end

  def tag_name
    @tag_name ||= data["ref"].gsub("refs/tags/", "")
  end
end
