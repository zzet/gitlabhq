class CreateEventSummaryEntityRelationships < ActiveRecord::Migration
  def change
    create_table :event_summary_entity_relationships do |t|
      t.integer :summary_id
      t.integer :entity_id
      t.string :entity_type
      t.string :options, array: true, default: '{}', using: 'gin'

      t.timestamps
    end
  end
end
