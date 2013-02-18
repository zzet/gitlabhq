class CreateNewEvent < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :author_id
      t.integer :action
      t.integer :source_id
      t.string :source_type
      t.text :data

      t.timestamps
    end
  end
end
