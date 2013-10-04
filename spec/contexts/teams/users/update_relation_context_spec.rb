require 'spec_helper'

describe Teams::Users::RemoveRelationContext do
  before do
    @user = create :user
    @user_1 = create :user

    opts = { name: "Team", description: "Team description" }
    @team = Teams::CreateContext.new(@user, opts).execute

    @user_params = { user_ids: "#{@user_1.id}", team_access: Gitlab::Access::DEVELOPER }
    Teams::Users::CreateRelationContext.new(@user, @team, @user_params).execute
  end

  it { @team.developers.include?(@user_1).should be_true }

  it "should update user role from developer to master" do
    Teams::Users::UpdateRelationContext.new(@user, @team, @user_1, { team_access: Gitlab::Access::MASTER }).execute

    @team.developers.include?(@user_1).should be_false
    @team.masters.include?(@user_1).should be_true
  end
end
