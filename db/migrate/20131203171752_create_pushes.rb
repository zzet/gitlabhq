class CreatePushes < ActiveRecord::Migration
  def change
    create_table :pushes do |t|
      t.string :ref
      t.string :before
      t.string :after
      t.text :data
      t.integer :project_id
      t.integer :user_id
      t.integer :commits_count

      t.timestamps
    end
  end
end
