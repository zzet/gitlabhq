class CreateFileTokens < ActiveRecord::Migration
  def change
    create_table :file_tokens do |t|
      t.integer :user_id
      t.integer :project_id
      t.string :token
      t.string :file
      t.datetime :last_usage_at
      t.integer :usage_count

      t.timestamps
    end
  end
end
