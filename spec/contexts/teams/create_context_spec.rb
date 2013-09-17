require 'spec_helper'

describe Teams::CreateContext do
  context 'non admin user' do
    before do
      @user = create :user, admin: false
      opts = { name: "Team", description: "Team description" }

      @team = Teams::CreateContext.new(@user, opts).execute
    end

    it { @team.should be_valid }
    it { @team.creator.should == @user }
  end
end
