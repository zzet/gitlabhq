require 'spec_helper'

describe Teams::Groups::CreateRelationContext do
  before do
    @user = create :user
    @team_opts = { name: "Team", description: "Team description" }
    @team = Teams::CreateContext.new(@user, @team_opts).execute
  end

  context 'non admin user' do
    context 'on own group' do
      before do
        group_opts = { name: "Gitlab" }
        @group = Groups::CreateContext.new(@user, group_opts).execute

        @group_team_rel_opts = { group_ids: "#{@group.id}" }
      end

      it "user should assign own team" do
        Teams::Groups::CreateRelationContext.new(@user, @team, @group_team_rel_opts).execute

        @team.groups.include?(@group).should be_true
      end

      it "shoul assign not own but public team" do
        @another_user = create :user
        @public_team_opts = { name: "Public Team", description: "Team description", public: true }
        @public_team = Teams::CreateContext.new(@another_user, @public_team_opts).execute

        Teams::Groups::CreateRelationContext.new(@user, @public_team, @group_team_rel_opts).execute

        @public_team.groups.include?(@group).should be_true
      end
    end
  end
end
