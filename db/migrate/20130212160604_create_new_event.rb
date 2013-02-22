class CreateNewEvent < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :author_id
      t.string :action

      t.integer :source_id
      t.string :source_type

      t.integer :target_id
      t.string :target_type

      t.text :data

      t.timestamps
    end
  end
end
