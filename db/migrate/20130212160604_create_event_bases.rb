class CreateEventBases < ActiveRecord::Migration
  def change
    create_table :event_bases do |t|
      t.integer :author_id
      t.string :action
      t.integer :target_id
      t.string :target_type
      t.text :data

      t.timestamps
    end
  end
end
