require 'spec_helper'

describe Teams::Users::CreateRelationContext do
  before do
    @user = create :user
    @team_opts = {
      name: "Team",
      description: "Team description"
    }
  end

  context 'non admin user' do
    before do
      @user.admin = false
      @user.save

      @team = create_team(@user, @team_opts)
      @users = []
      (1..3).each do
        @users << create(:user)
      end
    end

    context 'add guests' do
      before do
        add_guests(@users)
      end

      it { @team.guests.count.should == 3 }
    end

    context 'add reporters' do
      before do
        add_reporters(@users)
      end

      it { @team.reporters.count.should == 3 }
    end

    context 'add developers' do
      before do
        add_developers(@users)
      end

      it { @team.developers.count.should == 3 }
    end

    context 'add masters' do
      before do
        add_masters(@users)
      end

      it { @team.masters.count.should == 4 }
    end

    context 'add owners' do
      before do
        add_owners(@users)
      end

      it { @team.owners.count.should == 4 }
    end
  end

  def create_team(user, opts)
    team = Teams::CreateContext.new(user, opts).execute
    team
  end

  def add_users_with_role(users, role)
    @user_ids = users.map{ |u| u.id }.join(",")
    @params = {
      user_ids: @user_ids,
      team_access: role
    }

    Teams::Users::CreateRelationContext.new(@user, @team, @params).execute
  end

  def add_guests(users)
    add_users_with_role(users, Gitlab::Access::GUEST)
  end

  def add_reporters(users)
    add_users_with_role(users, Gitlab::Access::REPORTER)
  end

  def add_developers(users)
    add_users_with_role(users, Gitlab::Access::DEVELOPER)
  end

  def add_masters(users)
    add_users_with_role(users, Gitlab::Access::MASTER)
  end

  def add_owners(users)
    add_users_with_role(users, Gitlab::Access::OWNER)
  end

end
