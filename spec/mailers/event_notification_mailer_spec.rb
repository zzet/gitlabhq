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

    @project = create :project, creator: @user, path: 'gitlabhq'
    @group = create :group, owner: @user
    @user_team = create :user_team, owner: @user

    ActionMailer::Base.deliveries.clear
    EventHierarchyWorker.reset
  end

  let(:project) { create :project, creator: @another_user, namespace_id: @another_user }
  let(:group)   { create :group, owner: @another_user }
  let(:team)    { create :user_team, owner: @another_user }
  let(:user)    { create :user }

  describe "Project mails" do
    before do
      SubscriptionService.subscribe(@user, :all, :project, :all)
      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset
    end

    it "should send email about create project" do
      params = { project: attributes_for(:project) }
      Projects::CreateContext.new(@another_user, params).execute
      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about update project" do
      params = { project: attributes_for(:project) }
      Projects::UpdateContext.new(project, @another_user, params).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about destroy project" do
      ::Projects::RemoveContext.new(project, @another_user).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about create issue in project" do
      issue = create :issue, project: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update issue in project" do
      issue = create :issue, project: project

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      issue.title = "#{issue.title}_updated"
      issue.save

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about create milestone in project" do
      milestone = create :milestone, project: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update milestone in project" do
      milestone = create :milestone, project: project

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      milestone.title = "#{milestone.title}_updated"
      milestone.save

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about add note in project" do
      params = { note: attributes_for(:note) }
      Projects::Notes::CreateContext.new(project, @another_user, params).execute

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about add note in project with noteable" do
      note = create :note, project: project, noteable: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update note in project" do
      note = create :note, project: project, noteable: project

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      note.note = "#{note.note}_updated"
      note.save

      ActionMailer::Base.deliveries.should_not be_blank
    end


    it "should send email about create merge request in project" do
      merge_request = create :merge_request, project: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update merge request in project" do
      merge_request = create :merge_request, project: project

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      merge_request.title = "#{merge_request.title}_updated"
      merge_request.save

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about create protected branch in project" do
      protected_branch = create :protected_branch, project: project, name: "master"

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about create service in project" do
      service = create :service, project: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about create snippet in project" do
      snippet = create :snippet, project: project, author: @another_user

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about add web_hook in project" do
      project_hook = create :project_hook, project: project

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about project transfer from user namespace to group" do
      params = { project: attributes_for(:project) }
      project = Projects::CreateContext.new(@another_user, params).execute

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      params = { project: { namespace_id: group.id }}
      ::Projects::TransferContext.new(project, @another_user, params).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about project transfer from group to group" do
      old_group = create :group, owner: @another_user
      new_group = create :group, owner: @another_user
      project_in_group = create :project, creator: @another_user, namespace_id: old_group.id

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      params = { project: { namespace_id: new_group.id }}
      ::Projects::TransferContext.new(project_in_group, @another_user, params).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about project transfer from user to global namespace" do
      params = { project: { namespace_id: Namespace.global_id }}
      ::Projects::TransferContext.new(project, @another_user, params).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about project transfer from group to global namespace" do
      project_in_group = create :project, creator: @another_user, namespace_id: group.id

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      params = { project: { namespace_id: Namespace.global_id }}
      ::Projects::TransferContext.new(project_in_group, @another_user, params).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end
  end

  describe "Group mails" do
    before do
      SubscriptionService.subscribe(@user, :all, :group, :all)
    end

    it "should send email about create group" do
      new_group = create :group, owner: @another_user
      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update group" do
      group.name = "#{group.name}_updated"
      group.save

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about destroy group" do
      ::Groups::RemoveContext.new(group, @another_user).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about create project in group" do
      params = { project: attributes_for(:project), namespace_id: group.id }

      ::Projects::CreateContext.new(@another_user, params).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update project in group" do
      project.namespace = group
      project.save

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      params = { project: attributes_for(:project) }
      Projects::UpdateContext.new(project, @another_user, params).execute

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about delete project in group" do
      project.namespace = group
      project.save

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      ::Projects::RemoveContext.new(project, @another_user).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about transfer project between group" do
      old_group = create :group, owner: @another_user
      new_group = create :group, owner: @another_user
      project_in_group = create :project, creator: @another_user, namespace_id: old_group.id

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      params = { project: { namespace_id: new_group.id }}
      ::Projects::TransferContext.new(project_in_group, @another_user, params).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end


    it "should send email about assigned team to group" do
      params = { greatest_project_access: UsersProject::MASTER }
      Teams::Groups::CreateRelationContext.new(@another_user, team, group, params).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update relation team to group" do
      params = { greatest_project_access: UsersProject::MASTER }
      Teams::Groups::CreateRelationContext.new(@another_user, team, group, params).execute

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      params = { greatest_project_access: UsersProject::REPORTER, rebuild_flag: false }
      Teams::Groups::UpdateRelationContext.new(@another_user, team, group, params).execute

      ActionMailer::Base.deliveries.should_not be_blank

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      params = { greatest_project_access: UsersProject::DEVELOPER, rebuild_flag: true }
      Teams::Groups::UpdateRelationContext.new(@another_user, team, group, params).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about resign team from group" do
      params = { greatest_project_access: UsersProject::MASTER }
      Teams::Groups::CreateRelationContext.new(@another_user, team, group, params).execute

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      Teams::Groups::RemoveRelationContext.new(@another_user, team, group).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end
  end

  describe "UserTeams emails" do
    before do
      SubscriptionService.subscribe(@user, :all, :user_team, :all)
    end

    it "should send email about create team" do
      new_team = create :user_team, owner: @another_user
      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update team" do
      team.name = "#{team.name}_updated"
      team.save

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about destroy team" do
      ::Teams::RemoveContext.new(team, @another_user).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about assigned team to group" do
      SubscriptionService.subscribe(@user, :all, :group, :all)
      SubscriptionService.subscribe(@user, :all, :project, :all)

      project1 = create :project, namespace: group, creator: @another_user
      project2 = create :project, namespace: group, creator: @another_user

      user1 = create :user
      user2 = create :user

      Gitlab::UserTeamManager.add_member_into_team(team, user1, UsersProject::MASTER, true)
      Gitlab::UserTeamManager.add_member_into_team(team, user2, UsersProject::DEVELOPER, false)

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      params = { greatest_project_access: UsersProject::MASTER }
      Teams::Groups::CreateRelationContext.new(@another_user, team, group, params).execute

      ActionMailer::Base.deliveries.should_not be_blank
      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about update relation team to group" do
      params = { greatest_project_access: UsersProject::MASTER }
      Teams::Groups::CreateRelationContext.new(@another_user, team, group, params).execute

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      params = { greatest_project_access: UsersProject::REPORTER, rebuild_flag: false }
      Teams::Groups::UpdateRelationContext.new(@another_user, team, group, params).execute

      ActionMailer::Base.deliveries.should_not be_blank

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      params = { greatest_project_access: UsersProject::DEVELOPER, rebuild_flag: true }
      Teams::Groups::UpdateRelationContext.new(@another_user, team, group, params).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about resign team from group" do
      params = { greatest_project_access: UsersProject::MASTER }
      Teams::Groups::CreateRelationContext.new(@another_user, team, group, params).execute

      ActionMailer::Base.deliveries.clear
      EventHierarchyWorker.reset

      Teams::Groups::RemoveRelationContext.new(@another_user, team, group).execute

      ActionMailer::Base.deliveries.should_not be_blank
    end
  end

  describe "Users mails" do
    before do
      SubscriptionService.subscribe(@user, :all, :user, :all)
    end

    it "should send email about create user" do
      new_user = create :user
      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about update user" do
      user.name = "#{user.name}_updated"
      user.save

      ActionMailer::Base.deliveries.should_not be_blank
    end

    it "should send email about self key add" do
      key = create :key, user: user

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
        EventHierarchyWorker.reset

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        ActionMailer::Base.deliveries.should_not be_blank
      end
    end
  end
end
