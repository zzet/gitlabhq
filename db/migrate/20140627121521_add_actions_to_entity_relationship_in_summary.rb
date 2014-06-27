class AddActionsToEntityRelationshipInSummary < ActiveRecord::Migration
  def change
    add_column :event_summary_entity_relationships, :options_actions, :text
  end
end
