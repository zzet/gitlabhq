class CreateTeamGroupRelationships < ActiveRecord::Migration
  def change
    create_table :team_group_relationships do |t|
      t.integer :team_id
      t.integer :group_id

      t.timestamps
    end
  end
end
