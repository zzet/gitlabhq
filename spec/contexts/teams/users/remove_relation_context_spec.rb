require 'spec_helper'

describe Teams::Users::RemoveRelationContext do
  before do
    @user = create :user
    @user_1 = create :user
    opts = { name: "Team", description: "Team description" }
    @team = Teams::CreateContext.new(@user, opts).execute

    @user_params = {
      user_ids: "#{@user_1.id}",
      team_access: Gitlab::Access::DEVELOPER
    }

    Teams::Users::CreateRelationContext.new(@user, @team, @user_params).execute
  end

  it { @team.developers.include?(@user_1).should be_true }

  it "remove user from team" do
    Teams::Users::RemoveRelationContext.new(@user, @team, @user_1).execute
    @team.developers.include?(@user_1).should be_false
  end
end
