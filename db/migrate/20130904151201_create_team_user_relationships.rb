class CreateTeamUserRelationships < ActiveRecord::Migration
  def change
    create_table :team_user_relationships do |t|
      t.integer :user_id
      t.integer :team_id
      t.integer :team_access

      t.timestamps
    end
  end
end
