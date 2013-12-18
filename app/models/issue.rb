# == Schema Information
#
# Table name: issues
#
#  id           :integer          not null, primary key
#  title        :string(255)
#  assignee_id  :integer
#  author_id    :integer
#  project_id   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  position     :integer          default(0)
#  branch_name  :string(255)
#  description  :text
#  milestone_id :integer
#  state        :string(255)
#  iid          :integer
#

class Issue < ActiveRecord::Base
  include Issuable
  include InternalId

  ActsAsTaggableOn.strict_case_match = true

  attr_accessible :title, :assignee_id, :position, :description,
                  :milestone_id, :label_list, :author_id_of_changes,
                  :state_event

  belongs_to :project

  validates :project, presence: true

  acts_as_taggable_on :labels

  scope :of_group, ->(group) { where(project_id: group.project_ids) }
  scope :of_team, ->(team) { where(project_id: team.project_ids, assignee_id: team.member_ids) }
  scope :closed, -> { with_state(:closed) }

  scope :cared, ->(user) { where(assignee_id: user) }
  scope :open_for, ->(user) { opened.assigned_to(user) }

  state_machine :state, initial: :opened do
    event :close do
      transition [:reopened, :opened] => :closed
    end

    event :reopen do
      transition closed: :reopened
    end

    state :opened
    state :reopened
    state :closed
  end

  # Both open and reopened issues should be listed as opened
  scope :opened, -> { with_state(:opened, :reopened) }

  # Mentionable overrides.

  watch do
    source watchable_name do
      from :create,   to: :created
      from :update,   to: :assigned,   conditions: -> { @source.assignee_id_changed? && @changes['assignee_id'].first.nil? }
      from :update,   to: :reassigned, conditions: -> { @source.assignee_id_changed? && @changes['assignee_id'].first.present? && @changes['assignee_id'].last.present? }
      from :update,   to: :unassigned, conditions: -> { @source.assignee_id_changed? && @changes['assignee_id'].first.present? && @changes['assignee_id'].last.nil? }
      from :update,   to: :updated,    conditions: -> { @actions.count == 1 && [:title, :description, :branch_name].inject(false) { |m,v| m = m || @changes.has_key?(v.to_s) } }
      from :close,    to: :closed
      from :reopen,   to: :reopened
      from :destroy,  to: :deleted
    end

    source :note do
      before do: -> { @target = @source.noteable }, conditions: -> { @source.noteable.is_a?(Issue) }
      from :create,   to: :commented, conditions: -> { @source.noteable.is_a?(Issue) }
    end
  end

  def gfm_reference
    "issue ##{iid}"
  end
end
