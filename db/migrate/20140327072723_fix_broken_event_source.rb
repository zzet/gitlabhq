class FixBrokenEventSource < ActiveRecord::Migration
  def up
    Event.where(source_type: 'UserTeamProjectRelationship').delete_all
    Event.where(source_type: 'UserTeamUserRelationship').delete_all
    Event.where(source_type: 'UserTeam').delete_all
    Event.where(source_type: 'UserTeamGroupRelationship').delete_all
  end

  def down
  end
end
