require "spec_helper"

describe EventNotificationMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  before do
    @user = create :user
    @another_user = create :user

    ActiveRecord::Base.observers.enable :all

    Gitlab::Event::Action.current_user = @another_user

    SubscriptionService.subscribe(@user, :all, @user, :all)

    @project = create :project, creator: @user
    @group = create :group, owner: @user
    @user_team = create :user_team, owner: @user

    ActionMailer::Base.deliveries.clear
  end

  describe "Project mails" do
    before do
      SubscriptionService.subscribe(@user, :all, :project, :all)
    end

    it "should send email about create project" do
      project = create :project, creator: @another_user
      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update project" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

      project.name = "#{project.name}_updated"
      project.save

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about destroy project" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

      project.destroy

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about create issue in project" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

      issue = create :issue, project: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update issue in project" do
      project = create :project, creator: @another_user
      issue = create :issue, project: project

      ActionMailer::Base.deliveries.clear

      issue.title = "#{issue.title}_updated"
      issue.save

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about create milestone in project" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

      milestone = create :milestone, project: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update milestone in project" do
      project = create :project, creator: @another_user
      milestone = create :milestone, project: project

      ActionMailer::Base.deliveries.clear

      milestone.title = "#{milestone.title}_updated"
      milestone.save

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about add note in project" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

      note = create :note, project: project

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about add note in project with noteable" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

      note = create :note, project: project, noteable: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update note in project" do
      project = create :project, creator: @another_user
      note = create :note, project: project, noteable: project

      ActionMailer::Base.deliveries.clear

      note.note = "#{note.note}_updated"
      note.save

      ActionMailer::Base.deliveries.should_not be_blank
    end


    it "should send email about create merge request in project" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

      merge_request = create :merge_request, project: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update merge request in project" do
      project = create :project, creator: @another_user
      merge_request = create :merge_request, project: project

      ActionMailer::Base.deliveries.clear

      merge_request.title = "#{merge_request.title}_updated"
      merge_request.save

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about create protected branch in project" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

      protected_branch = create :protected_branch, project: project, name: "master"

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about create service in project" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

      service = create :service, project: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about create snippet in project" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

      snippet = create :snippet, project: project, author: @another_user

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about add web_hook in project" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

      project_hook = create :project_hook, project: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about project transfer from user namespace to group" do
      project = create :project, creator: @another_user
      group = create :group, owner: @another_user

      ActionMailer::Base.deliveries.clear

       project.namespace = group
       project.save

       ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about project transfer from group to group" do
      old_group = create :group, owner: @another_user
      new_group = create :group, owner: @another_user
      project = create :project, creator: @another_user, namespace: old_group

      ActionMailer::Base.deliveries.clear

       project.namespace = new_group
       project.save

       ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about project transfer from user to global namespace" do
      project = create :project, creator: @another_user

      ActionMailer::Base.deliveries.clear

       project.namespace_id = Namespace.global_id
       project.save

       ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about project transfer from group to global namespace" do
      group = create :group, owner: @another_user
      project = create :project, creator: @another_user, namespace_id: group.id

      ActionMailer::Base.deliveries.clear

       project.namespace_id = Namespace.global_id
       project.save

       ActionMailer::Base.deliveries.should_not be_blank
    end
  end

  describe "Group mails" do
    before do
      SubscriptionService.subscribe(@user, :all, :group, :all)
    end

    it "should send email about create group" do
      group = create :group, owner: @another_user
      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update group" do
      group = create :group, owner: @another_user

      ActionMailer::Base.deliveries.clear

      group.name = "#{group.name}_updated"
      group.save

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about destroy group" do
      group = create :group, owner: @another_user

      ActionMailer::Base.deliveries.clear

      group.destroy

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about create project in group" do
      group = create :group, owner: @another_user

      ActionMailer::Base.deliveries.clear

      project = create :project, creator: @another_user, namespace: group

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update project in group" do
      group = create :group, owner: @another_user

      SubscriptionService.subscribe(@user, :all, group, :project)

      project = create :project, creator: @another_user, namespace: group

      ActionMailer::Base.deliveries.clear

      project.name = "#{project.name}_updated"
      project.save

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send emails without dublicates about update project in group" do
      group = create :group, owner: @another_user

      SubscriptionService.subscribe(@user, :all, :project, :all)
      SubscriptionService.subscribe(@user, :all, group, :project)

      project = create :project, creator: @another_user, namespace: group

      ActionMailer::Base.deliveries.clear

      project.name = "#{project.name}_updated"
      project.save

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about delete project in group" do
      group = create :group, owner: @another_user
      project = create :project, creator: @another_user, namespace: group

      ActionMailer::Base.deliveries.clear

      project.destroy

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about transfer project between group" do
      old_group = create :group, owner: @another_user
      new_group = create :group, owner: @another_user
      project = create :project, creator: @another_user, namespace: old_group

      ActionMailer::Base.deliveries.clear

      project.namespace = new_group
      project.save

      ActionMailer::Base.deliveries.should_not be_blank
    end


    it "should send email about assigned team to group" do
      group = create :group, owner: @another_user
      team = create :user_team, owner: @another_user

      ActionMailer::Base.deliveries.clear

      Gitlab::UserTeamManager.assign_to_group(team, group, UsersProject::MASTER)

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update relation team to group" do
      group = create :group, owner: @another_user
      team = create :user_team, owner: @another_user
      Gitlab::UserTeamManager.assign_to_group(team, group, UsersProject::MASTER)

      ActionMailer::Base.deliveries.clear

      utgr = group.user_team_group_relationships.find_by_user_team_id(team.id)
      utgr.greatest_access = UsersProject::DEVELOPER
      utgr.save

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about resign team from group" do
      group = create :group, owner: @another_user
      team = create :user_team, owner: @another_user
      Gitlab::UserTeamManager.assign_to_group(team, group, UsersProject::MASTER)

      ActionMailer::Base.deliveries.clear

      Gitlab::UserTeamManager.resign_from_group(team, group)

      ActionMailer::Base.deliveries.should_not be_blank
    end
  end

  describe "UserTeams emails" do
    before do
      SubscriptionService.subscribe(@user, :all, :user_team, :all)
    end

    it "should send email about create team" do
      team = create :user_team, owner: @another_user
      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update team" do
      team = create :user_team, owner: @another_user

      ActionMailer::Base.deliveries.clear

      team.name = "#{team.name}_updated"
      team.save

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about destroy team" do
      team = create :user_team, owner: @another_user

      ActionMailer::Base.deliveries.clear

      team.destroy

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about assigned team to group" do
      group = create :group, owner: @another_user
      team = create :user_team, owner: @another_user

      ActionMailer::Base.deliveries.clear

      Gitlab::UserTeamManager.assign_to_group(team, group, UsersProject::MASTER)

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update relation team to group" do
      group = create :group, owner: @another_user
      team = create :user_team, owner: @another_user
      Gitlab::UserTeamManager.assign_to_group(team, group, UsersProject::MASTER)

      ActionMailer::Base.deliveries.clear

      utgr = group.user_team_group_relationships.find_by_user_team_id(team.id)
      utgr.greatest_access = UsersProject::DEVELOPER
      utgr.save

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about resign team from group" do
      group = create :group, owner: @another_user
      team = create :user_team, owner: @another_user
      Gitlab::UserTeamManager.assign_to_group(team, group, UsersProject::MASTER)

      ActionMailer::Base.deliveries.clear

      Gitlab::UserTeamManager.resign_from_group(team, group)

      ActionMailer::Base.deliveries.should_not be_blank
    end
  end

  describe "Users mails" do
    before do
      SubscriptionService.subscribe(@user, :all, :user, :all)
    end

    it "should send email about create user" do
      user = create :user
      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update user" do
      user = create :user

      ActionMailer::Base.deliveries.clear

      user.name = "#{user.name}_updated"
      user.save

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about self key add" do
      key = create :key, user: @user

      ActionMailer::Base.deliveries.should_not be_blank
    end
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

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        ActionMailer::Base.deliveries.should_not be_blank
      end
    end
  end
end
