class RemoveUserTeamRelationTables < ActiveRecord::Migration
  def change
    drop_table :user_team_group_relationships
    drop_table :user_team_project_relationships
    drop_table :user_team_user_relationships
    drop_table :user_teams
  end
end
