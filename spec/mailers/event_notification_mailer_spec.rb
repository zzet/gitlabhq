require "spec_helper"

describe EventNotificationMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  before do
    @user = create :user
    @another_user = create :user

    Gitlab::Event::Action.current_user = @user
    SubscriptionService.subscribe(@user, :all, @user, :all)
    SubscriptionService.subscribe(@user, :all, :group, :all)
    SubscriptionService.subscribe(@user, :all, :project, :all)
    SubscriptionService.subscribe(@user, :all, :user_team, :all)
    SubscriptionService.subscribe(@user, :all, :user, :all)

    @project = create :project, creator: @user
    @group = create :group, owner: @user
    @user_team = create :user_team, owner: @user

    ActionMailer::Base.deliveries.clear
  end

  it "should send email about create project" do
    project = create :project, creator: @another_user
    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about create group" do
    group = create :group, owner: @another_user
    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about create team" do
    team = create :user_team, owner: @another_user
    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about create user" do
    user = create :user
    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about update project" do
    project = create :project, creator: @another_user

    ActionMailer::Base.deliveries.clear

    project.name = "#{project.name}_updated"
    project.save

    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about update group" do
    group = create :group, owner: @another_user

    ActionMailer::Base.deliveries.clear

    group.name = "#{group.name}_updated"
    group.save

    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about update team" do
    team = create :user_team, owner: @another_user

    ActionMailer::Base.deliveries.clear

    team.name = "#{team.name}_updated"
    team.save

    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about update user" do
    user = create :user

    ActionMailer::Base.deliveries.clear

    user.name = "#{user.name}_updated"
    user.save

    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about destroy project" do
    project = create :project, creator: @another_user

    ActionMailer::Base.deliveries.clear

    project.destroy

    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about destroy group" do
    group = create :group, owner: @another_user

    ActionMailer::Base.deliveries.clear

    group.destroy

    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about destroy team" do
    team = create :user_team, owner: @another_user

    ActionMailer::Base.deliveries.clear

    team.destroy

    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about destroy user" do
    user = create :user

    ActionMailer::Base.deliveries.clear

    user.destroy

    ActionMailer::Base.deliveries.should_not be_blank
  end

  it "should send email about self key add" do
    key = create :key, user: @user

    ActionMailer::Base.deliveries.should_not be_blank
  end

  describe "Push actions mails" do

    before do
      @service = GitPushService.new
      @oldrev = 'b98a310def241a6fd9c9a9a3e7934c48e498fe81'
      @newrev = 'b19a04f53caeebf4fe5ec2327cb83e9253dc91bb'
      @ref = 'refs/heads/master'
    end

    describe "Push Events" do
      it "should send email with summary push info "  do
        ActionMailer::Base.deliveries.clear

        @service.execute(@project, @user, @oldrev, @newrev, @ref)

        p ActionMailer::Base.deliveries.inspect
        ActionMailer::Base.deliveries.should_not be_blank
        p ActionMailer::Base.deliveries.first.body.inspect
      end
    end
  end
end
