class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name
      t.string :path
      t.text :description
      t.integer :creator_id
      t.boolean :public

      t.timestamps
    end
  end
end
