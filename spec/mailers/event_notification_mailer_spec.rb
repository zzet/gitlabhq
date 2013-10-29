require "spec_helper"

describe EventNotificationMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  before do
    @user = create :user
    @another_user = create :user
    @user.create_notification_setting
    @user.notification_setting.brave = true
    @user.notification_setting.save

    ActiveRecord::Base.observers.enable :all
    RequestStore.store[:current_user] = @another_user

    ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset
  end

  let(:group)   { g = create :group, owner: @another_user; ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset; g }
  let(:project) { pr = create :project_with_code, creator: @another_user, path: 'gitlabhq', namespace: group; Event::Subscription::Notification.destroy_all; ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset; pr }
  let(:team)    { t = create :team, creator: @another_user; ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset; t }
  let(:user)    { u = create :user; ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset; u }

  describe "Project mails" do
    before(:each) do
      SubscriptionService.subscribe(@user, :all, :project, :all)
      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset
    end

    it "should send email about create project" do
      params = { project: attributes_for(:project_with_code) }
      pr = Projects::CreateContext.new(user, params[:project]).execute
      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about update project" do
      params = { project: attributes_for(:project) }
      Projects::UpdateContext.new(@another_user, project, params).execute
      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about destroy project" do
      EventSubscriptionCleanWorker.any_instance.stub(:perform).and_return(true)
      ::Projects::RemoveContext.new(@another_user, project).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about create issue in project" do
      issue = create :issue, project: project

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about update issue in project" do
      issue = create :issue, project: project

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      issue.title = "#{issue.title}_updated"
      issue.save

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about create milestone in project" do
      milestone = create :milestone, project: project

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about update milestone in project" do
      milestone = create :milestone, project: project

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      milestone.title = "#{milestone.title}_updated"
      milestone.save

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about add note in project" do
      params = { note: attributes_for(:note) }
      Projects::Notes::CreateContext.new(@another_user, project, params).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should not send email about add note in project with noteable" do
      note = create :note, project: project, noteable: project

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about add note on commit in project" do
      @user = create :user, { email: "dmitriy.zaporozhets@gmail.com" }
      @project = create :project_with_code, path: 'gitlabhq'

      @project.team << [@user, 40]

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      note = create :note, project: @project, commit_id: "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a", noteable_type: "Commit"

      ActionMailer::Base.deliveries.count.should == 2
    end

    it "should send email about update note in project" do
      note = create :note, project: project, noteable: project

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      note.note = "#{note.note}_updated"
      note.save

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about create merge request in project" do
      merge_request = create :merge_request, source_project: project, target_project: project

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about assignee merge request" do
      merge_request = create :merge_request, source_project: project, target_project: project

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      params = {
        merge_request: {
          assignee_id: @user.id
        }
      }
      context = ::Projects::MergeRequests::UpdateContext.new(@user, project, merge_request, params)
      context.execute

      ActionMailer::Base.deliveries.count.should == 2
    end

    it "should send email about reassignee merge request" do
      merge_request = create :merge_request, source_project: project, target_project: project, assignee_id: @user.id

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      params = {
        merge_request: {
          assignee_id: @another_user.id
        }
      }
      context = ::Projects::MergeRequests::UpdateContext.new(@user, project, merge_request, params)
      context.execute

      ActionMailer::Base.deliveries.count.should == 2
    end

    it "should send email about create assigned merge request in project" do
      merge_request = create :merge_request, source_project: project, target_project: project, assignee: @user

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about add note in project merge request" do
      merge_request = create :merge_request, source_project: project, target_project: project

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      note = create :note, project: project, noteable: merge_request

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about update merge request in project" do
      merge_request = create :merge_request, source_project: project, target_project: project

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      merge_request.title = "#{merge_request.title}_updated"
      merge_request.save

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about merge merge request in project" do
      merge_request = create :merge_request, source_project: project, target_project: project

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      merge_request.merge

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about close merge request in project" do
      merge_request = create :merge_request, source_project: project, target_project: project

      Event::Subscription::Notification.destroy_all
      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      params = { merge_request: { state_event: :close } }
      Projects::MergeRequests::UpdateContext.new(@another_user, project, merge_request, params).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about reopen merge request in project" do
      merge_request = create :merge_request, source_project: project, target_project: project

      params = { merge_request: { state_event: :close } }
      Projects::MergeRequests::UpdateContext.new(@another_user, project, merge_request, params).execute

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      params = { merge_request: { state_event: :reopen } }
      Projects::MergeRequests::UpdateContext.new(@another_user, project, merge_request, params).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about create protected branch in project" do
      protected_branch = create :protected_branch, project: project, name: "master"

      ActionMailer::Base.deliveries.count.should == 1
    end

    Service.implement_services.map {|s| s.new }.each do |service|
      it "should send email about create service in project" do
        @new_service = create :"#{service.to_param}_service"
        #service = create :service, project: project

        ActionMailer::Base.deliveries.count.should == 1
      end
    end

    it "should send email about create snippet in project" do
      snippet = create :project_snippet, project: project, author: @another_user

      ActionMailer::Base.deliveries.should be_blank
    end

    it "should send email about add web_hook in project" do
      project_hook = create :project_hook, project: project

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about project transfer from user namespace to group" do
      group
      params = { project: attributes_for(:project_with_code) }
      project = Projects::CreateContext.new(user, params[:project]).execute

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      ::Projects::TransferContext.new(user, project, group).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about project transfer from group to group" do
      old_group = create :group, owner: @another_user
      new_group = create :group, owner: @another_user

      params = { project: attributes_for(:project, creator_id: @another_user.id, namespace_id: old_group.id) }
      project_in_group = Projects::CreateContext.new(@another_user, params[:project]).execute

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      ::Projects::TransferContext.new(@another_user, project_in_group, new_group).execute

      ActionMailer::Base.deliveries.count.should == 1
    end
  end

  describe "Group mails" do
    before do
      SubscriptionService.subscribe(@user, :all, :group, :all)
      Event.destroy_all
    end

    it "should send email about create group" do
      new_group = create :group, owner: @another_user
      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about update group" do
      group.name = "#{group.name}_updated"
      group.save

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about destroy group" do
      EventSubscriptionCleanWorker.any_instance.stub(:perform).and_return(true)
      ::Groups::RemoveContext.new(@another_user, group).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about create project in group" do
      params = { project: attributes_for(:project, namespace_id: group.id) }

      ::Projects::CreateContext.new(@another_user, params[:project]).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about update project in group" do
      SubscriptionService.subscribe(@user, :all, group, :project)
      project.namespace = group
      project.save

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      params = { project: attributes_for(:project) }
      Projects::UpdateContext.new(@another_user, project, params).execute

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
      project.namespace = group
      project.save

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      ::Projects::RemoveContext.new(@another_user, project).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about assigned team to group" do
      team
      group

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about resign team from group" do
      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      Teams::Groups::RemoveRelationContext.new(@another_user, team, group).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about add user into group team" do
      params = { user_ids: "#{user.id}", group_access: Gitlab::Access::MASTER }
      Groups::Users::CreateRelationContext.new(@another_user, group, params).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about remove user from group team" do
      params = { user_ids: "#{user.id}", group_access: Gitlab::Access::MASTER }
      Groups::Users::CreateRelationContext.new(@another_user, group, params).execute

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      Groups::Users::RemoveRelationContext.new(@another_user, group, user).execute

      ActionMailer::Base.deliveries.count.should == 1
    end


  end

  describe "Teams emails" do
    before do
      SubscriptionService.subscribe(@user, :all, :team, :all)
    end

    it "should send email about create team" do
      new_team = create :team, creator: @another_user
      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about update team" do
      team.name = "#{team.name}_updated"
      team.save

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about destroy team" do
      EventSubscriptionCleanWorker.any_instance.stub(:perform).and_return(true)
      ::Teams::RemoveContext.new(@another_user, team).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about assigned team to group" do
      SubscriptionService.subscribe(@user, :all, :group, :all)
      SubscriptionService.subscribe(@user, :all, :project, :all)

      project1 = create :project, namespace: group, creator: @another_user
      project2 = create :project, namespace: group, creator: @another_user

      user1 = create :user
      user2 = create :user

      params = { user_ids: "#{user1.id}", team_access: Gitlab::Access::MASTER }
      Teams::Users::CreateRelationContext.new(@another_user, team, params)

      params = { user_ids: "#{user2.id}", team_access: Gitlab::Access::DEVELOPER }
      Teams::Users::CreateRelationContext.new(@another_user, team, params)

      Event::Subscription::Notification.destroy_all
      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about add new member into team on assigned team to group" do
      SubscriptionService.subscribe(@user, :all, :group, :all)
      SubscriptionService.subscribe(@user, :all, :project, :all)

      project1 = create :project, namespace: group, creator: @another_user
      project2 = create :project, namespace: group, creator: @another_user

      user1 = create :user
      user2 = create :user
      user3 = create :user

      params = { user_ids: "#{user1.id}, #{user2.id}", team_access: Gitlab::Access::MASTER }
      ::Teams::Users::CreateRelationContext.new(@another_user, team, params).execute

      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      params = { user_ids: "#{user2.id}", team_access: Gitlab::Access::DEVELOPER }
      Teams::Users::CreateRelationContext.new(@another_user, team, params)

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about update member into team on assigned team to group" do
      SubscriptionService.subscribe(@user, :all, :group, :all)
      SubscriptionService.subscribe(@user, :all, :project, :all)

      project1 = create :project, namespace: group, creator: @another_user
      project2 = create :project, namespace: group, creator: @another_user

      user1 = create :user
      user2 = create :user
      user3 = create :user

      params = { user_ids: [user1.id, user2.id, user3.id], team_access: Gitlab::Access::MASTER }
      ::Teams::Users::CreateRelationContext.new(@another_user, team, params).execute

      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      params = { team_member: { team_access: Gitlab::Access::REPORTER } }
      ::Teams::Users::UpdateRelationContext.new(@another_user, team, user3, params[:team_member]).execute

      ActionMailer::Base.deliveries.count.should == 1

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      params = { team_member: { team_access: Gitlab::Access::DEVELOPER } }
      ::Teams::Users::UpdateRelationContext.new(@another_user, team, user3, params[:team_member]).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about assigned team to group with subscriptions on projects only" do
      SubscriptionService.subscribe(@user, :all, :project, :all)

      project1 = create :project, namespace: group, creator: @another_user
      project2 = create :project, namespace: group, creator: @another_user

      Event::Subscription.by_user(@user).by_target(project1).count.should == 1
      Event::Subscription.by_user(@user).by_target(project2).count.should == 1

      user1 = create :user
      user2 = create :user

      params = { user_ids: "#{user1.id}", team_access: Gitlab::Access::MASTER }
      Teams::Users::CreateRelationContext.new(@another_user, team, params)

      params = { user_ids: "#{user2.id}", team_access: Gitlab::Access::DEVELOPER }
      Teams::Users::CreateRelationContext.new(@another_user, team, params)

      Event::Subscription::Notification.destroy_all
      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about resign team from group" do
      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      Teams::Groups::RemoveRelationContext.new(@another_user, team, group).execute

      ActionMailer::Base.deliveries.count.should == 1
    end
  end

  describe "Users mails" do
    before do
      SubscriptionService.subscribe(@user, :all, :user, :all)
    end

    it "should send email about create user" do
      new_user = create :user
      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about update user" do

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      Users::BlockContext.new(@user, user).execute

      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should send email about block user" do
      user.name = "#{user.name}_updated"
      user.save

      ActionMailer::Base.deliveries.count.should == 1
    end



    it "should send email about self key add" do
      key = create :key, user: user

      ActionMailer::Base.deliveries.count.should == 1
    end
  end

  describe "Push actions mails" do

    before do
      SubscriptionService.subscribe(@user, :all, :project, :all)

      @service = GitPushService.new
      @oldrev = 'b98a310def241a6fd9c9a9a3e7934c48e498fe81'
      @newrev = 'b19a04f53caeebf4fe5ec2327cb83e9253dc91bb'
      @ref = 'refs/heads/master'
      @project = project
      @project.default_branch = 'master'
      @project.save

      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset
    end

    describe "Push Events" do
      it "should send email with summary push info "  do
        ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        ActionMailer::Base.deliveries.count.should == 1
      end
    end

    describe "Push Events with create branch" do
      it "should send email with created branch push info "  do
        @oldrev = '0000000000000000000000000000000000000000'

        ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        ActionMailer::Base.deliveries.count.should == 1
      end
    end

    describe "Push Events with create branch" do
      it "should send email with created tag push info "  do
        @oldrev = '0000000000000000000000000000000000000000'
        @ref = 'refs/tags/v2.2.0'

        ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        ActionMailer::Base.deliveries.count.should == 1
      end

    end

    describe "Push Events with create branch" do
      it "should send email with delete branch push info "  do
        @newrev = '0000000000000000000000000000000000000000'

        ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        ActionMailer::Base.deliveries.count.should == 1
      end
    end

    describe "Push Events with create branch" do
      it "should send email with delete tag push info "  do
        @newrev = '0000000000000000000000000000000000000000'
        @ref = 'refs/tags/v2.2.0'

        ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        ActionMailer::Base.deliveries.count.should == 1
      end

    end
  end
end
