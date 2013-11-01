class CreateCiBuilds < ActiveRecord::Migration
  def change
    create_table :ci_builds do |t|
      t.integer :user_id
      t.integer :target_project_id
      t.integer :source_project_id
      t.integer :merge_request_id
      t.integer :service_id
      t.string  :service_type
      t.string :source_sha
      t.string :target_sha
      t.string :state
      t.text :trace
      t.text :coverage
      t.text :data

      t.timestamps
    end
  end
end
