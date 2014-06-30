# == Schema Information
#
# Table name: event_summary_entity_relationships
#
#  id          :integer          not null, primary key
#  summary_id  :integer
#  entity_id   :integer
#  entity_type :string(255)
#  options     :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class Event::SummaryEntityRelationship < ActiveRecord::Base

  attr_accessible :summary_id, :entity_id, :entity_type, :options, :options_actions

  serialize :options_actions, Hash

  belongs_to :summary
  belongs_to :entity, polymorphic: true

  validates :summary, presence: true
  validates :entity,  presence: true
  validates :entity_id, uniqueness: { scope: [:entity_type, :summary_id] }

  # Return list of active action sources
  def active_sources
    return @active_options if defined?(@active_options)

    source_klass = entity_type.constantize
    @active_options = if options.any?
                        source_klass.watched_sources & options.map  do |o|
                          o.to_sym
                        end
                      else
                        source_klass.watched_sources
                      end
  end

  # Return list of action for target - source relation
  def active_actions_for_source(source)
    source_klass = entity_type.constantize

    oa = options_actions
    if oa.is_a?(Hash) && oa.any? && oa[source]
      oa[source].map {|k, v| k.to_sym}.keep_if do |k|
        source_klass.result_actions_names(source).include?(k)
      end
    else
      source_klass.result_actions_names(source)
    end
  end
end
