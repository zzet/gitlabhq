require "spec_helper"

describe EventNotificationMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  def clear_prepare_data
    Event::Subscription::Notification.destroy_all; ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset;
  end

  subject(:mails) { ActionMailer::Base.deliveries }

  def mail_count
    ActionMailer::Base.deliveries.count
  end

  let(:user)    { u  = nil; ActiveRecord::Base.observers.enable(:user_observer) { u = create(:user);};        clear_prepare_data; u }
  let(:group)   { g  = create :group,             owner:   @another_user;                                     clear_prepare_data; g }
  let(:project) { pr = create :project_with_code, creator: @another_user, path: 'gitlabhq', namespace: group; clear_prepare_data; pr }
  let(:team)    { t  = create :team,              creator: @another_user;                                     clear_prepare_data; t }

  before do
    @user = create :user
    @another_user = user
    @user.create_notification_setting(brave: true)

    RequestStore.store[:current_user] = @another_user

    clear_prepare_data

    ActiveRecord::Base.observers.enable :all
  end

  describe "Project mails" do
    before(:each) do
      SubscriptionService.subscribe(@user, :all, :project, :all)
      clear_prepare_data
    end

    context "when create project" do
      before do
        params = { project: attributes_for(:project_with_code) }
        Projects::CreateContext.new(user, params[:project]).execute
      end

      it { mails.count.should == 1 }
    end

    context "when update project" do
      before do
        params = { project: attributes_for(:project) }
        Projects::UpdateContext.new(@another_user, project, params).execute
      end

      it { mails.count.should == 1 }
    end

    context "when destroy project" do
      before do
        EventSubscriptionCleanWorker.any_instance.stub(:perform).and_return(true)
        ::Projects::RemoveContext.new(@another_user, project).execute
      end

      it { mails.count.should == 1 }
    end

    it "should send email about create issue in project" do
      create :issue, project: project

      mail_count.should == 1
    end

    it "should send email about create milestone in project" do
      create :milestone, project: project

      mail_count.should == 1
    end

    it "should send email about add note in project" do
      params = { note: attributes_for(:note) }
      Projects::Notes::CreateContext.new(@another_user, project, params).execute

      mail_count.should == 1
    end

    it "should send email about add note on commit in project" do
      @user = create :user, { email: "dmitriy.zaporozhets@gmail.com" }
      @project = create :project_with_code, path: 'gitlabhq'

      @project.team << [@user, 40]

      clear_prepare_data

      create :note, project: @project, commit_id: "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a", noteable_type: "Commit"

      mail_count.should == 2
    end

    it "not send email about update note in project" do
      note = create :note, project: project, noteable: project

      clear_prepare_data

      note.note = "#{note.note}_updated"
      note.save

      mail_count.should == 0
    end

    it "should send email about create merge request in project" do
      create :merge_request, source_project: project, target_project: project

      mail_count.should == 1
    end

    it "should send email about assignee merge request" do
      merge_request = create :merge_request, source_project: project, target_project: project

      clear_prepare_data

      params = {
        merge_request: {
          assignee_id: @another_user.id
        }
      }

      ::Projects::MergeRequests::UpdateContext.new(@user, project, merge_request, params).execute

      mail_count.should == 1
    end

    it "should send email about reassignee merge request" do
      merge_request = create :merge_request, source_project: project, target_project: project, assignee_id: @another_user.id

      clear_prepare_data

      params = {
        merge_request: {
          assignee_id: @user.id
        }
      }

      ::Projects::MergeRequests::UpdateContext.new(@user, project, merge_request, params).execute

      mail_count.should == 1
    end

    it "should send email about create assigned merge request in project" do
      create :merge_request, source_project: project, target_project: project, assignee: @user

      mail_count.should == 1
    end

    it "should send email about add note in project merge request" do
      merge_request = create :merge_request, source_project: project, target_project: project

      clear_prepare_data

      create :note, project: project, noteable: merge_request

      mail_count.should == 1
    end

    it "not send email about update merge request in project" do
      merge_request = create :merge_request, source_project: project, target_project: project

      clear_prepare_data

      merge_request.title = "#{merge_request.title}_updated"
      merge_request.save

      mail_count.should == 0
    end

    it "should send email about merge merge request in project" do
      merge_request = create :merge_request, source_project: project, target_project: project

      clear_prepare_data

      merge_request.merge

      mail_count.should == 1
    end

    it "should send email about close merge request in project" do
      merge_request = create :merge_request, source_project: project, target_project: project

      clear_prepare_data

      params = { merge_request: { state_event: :close } }
      Projects::MergeRequests::UpdateContext.new(@another_user, project, merge_request, params).execute

      mail_count.should == 1
    end

    it "should send email about reopen merge request in project" do
      merge_request = create :merge_request, source_project: project, target_project: project

      params = { merge_request: { state_event: :close } }
      Projects::MergeRequests::UpdateContext.new(@another_user, project, merge_request, params).execute

      clear_prepare_data

      params = { merge_request: { state_event: :reopen } }
      Projects::MergeRequests::UpdateContext.new(@another_user, project, merge_request, params).execute

      mail_count.should == 1
    end

    it "should send email about create protected branch in project" do
      create :protected_branch, project: project, name: "master"

      mail_count.should == 1
    end

    Service.implement_services.map {|s| s.new }.each do |service|
      it "not should send email about create #{service.to_param} service in project" do
        @service = create :"#{service.to_param}_service"

        mail_count.should == 0
      end
    end

    it "not should send email about create snippet in project" do
      create :project_snippet, project: project, author: @another_user

      mail_count.should == 0
    end

    it "should send email about add web_hook in project" do
      create :project_hook, project: project

      mail_count.should == 1
    end

    it "should send email about project transfer from user namespace to group" do
      group
      params = { project: attributes_for(:project_with_code) }
      project = Projects::CreateContext.new(user, params[:project]).execute

      clear_prepare_data

      ::Projects::TransferContext.new(user, project, group).execute

      mail_count.should == 1
    end

    it "should send email about project transfer from group to group" do
      old_group = create :group, owner: @another_user
      new_group = create :group, owner: @another_user

      params = { project: attributes_for(:project, creator_id: @another_user.id, namespace_id: old_group.id) }
      project_in_group = Projects::CreateContext.new(@another_user, params[:project]).execute

      clear_prepare_data

      ::Projects::TransferContext.new(@another_user, project_in_group, new_group).execute

      mail_count.should == 1
    end
  end

  describe "Group mails" do
    before do
      SubscriptionService.subscribe(@user, :all, :group, :all)
      Event.destroy_all
    end

    it "should send email about create group" do
      create :group, owner: @another_user
      mail_count.should == 1
    end

    it "should send email about update group" do
      group.name = "#{group.name}_updated"
      group.save

      mail_count.should == 1
    end

    it "should send email about destroy group" do
      group
      EventSubscriptionCleanWorker.any_instance.stub(:perform).and_return(true)

      #binding.pry
      ::Groups::RemoveContext.new(@another_user, group).execute

      mail_count.should == 1
    end

    it "should send email about create project in group" do
      group

      params = { project: attributes_for(:project_with_code, namespace_id: group.id) }

      #binding.pry
      ::Projects::CreateContext.new(@another_user, params[:project]).execute

      mail_count.should == 1
    end

    it "should send email about update project in group" do
      SubscriptionService.subscribe(@user, :all, group, :project)

      project

      clear_prepare_data

      params = { project: attributes_for(:project) }
      Projects::UpdateContext.new(@another_user, project, params).execute

      mail_count.should == 1
    end

    it "should send emails without dublicates about update project in group" do
      project

      SubscriptionService.subscribe(@user, :all, :project, :all)
      SubscriptionService.subscribe(@user, :all, group, :project)

      clear_prepare_data

      project.name = "#{project.name}_updated"
      project.save

      mail_count.should == 1
    end

    it "should send email about delete project in group" do
      project

      ::Projects::RemoveContext.new(@another_user, project).execute

      mail_count.should == 1
    end

    it "should send email about assigned team to group" do
      team
      group

      clear_prepare_data

      #binding.pry

      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      mail_count.should == 1
    end

    it "should send email about resign team from group" do
      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      clear_prepare_data

      Teams::Groups::RemoveRelationContext.new(@another_user, team, group).execute

      mail_count.should == 1
    end

    it "should send email about add user into group team" do
      group
      user

      #binding.pry

      params = { user_ids: "#{user.id}", group_access: Gitlab::Access::MASTER }
      Groups::Users::CreateRelationContext.new(@another_user, group, params).execute

      mail_count.should == 1
    end

    it "should send email about remove user from group team" do
      user = create :user

      params = { user_ids: "#{user.id}", group_access: Gitlab::Access::MASTER }
      Groups::Users::CreateRelationContext.new(@another_user, group, params).execute

      clear_prepare_data

      Groups::Users::RemoveRelationContext.new(@another_user, group, user).execute

      mail_count.should == 1
    end
  end

  describe "Teams emails" do
    before do
      SubscriptionService.subscribe(@user, :all, :team, :all)
    end

    it "should send email about create team" do
      create :team, creator: @another_user

      mail_count.should == 1
    end

    it "should send email about update team" do
      team.name = "#{team.name}_updated"
      team.save

      mail_count.should == 1
    end

    it "should send email about destroy team" do
      EventSubscriptionCleanWorker.any_instance.stub(:perform).and_return(true)
      ::Teams::RemoveContext.new(@another_user, team).execute

      mail_count.should == 1
    end

    it "should send email about assigned team to group" do
      SubscriptionService.subscribe(@user, :all, :group, :all)
      SubscriptionService.subscribe(@user, :all, :project, :all)

      double(create :project, namespace: group, creator: @another_user)

      user1 = create :user
      user2 = create :user

      params = { user_ids: "#{user1.id}", team_access: Gitlab::Access::MASTER }
      Teams::Users::CreateRelationContext.new(@another_user, team, params)

      params = { user_ids: "#{user2.id}", team_access: Gitlab::Access::DEVELOPER }
      Teams::Users::CreateRelationContext.new(@another_user, team, params)

      clear_prepare_data

      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      mail_count.should == 1
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

      clear_prepare_data

      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      mail_count.should == 1
    end

    it "should send email about resign team from group" do
      params = { group_ids: "#{group.id}" }
      Teams::Groups::CreateRelationContext.new(@another_user, team, params).execute

      clear_prepare_data

      Teams::Groups::RemoveRelationContext.new(@another_user, team, group).execute

      mail_count.should == 1
    end
  end

  describe "Users mails" do
    before do
      SubscriptionService.subscribe(@user, :all, :user, :all)
    end

    it "should send email about create user" do
      create :user
      mail_count.should == 1
    end

    it "should send email about update user" do
      user = create :user

      clear_prepare_data

      user.name = "#{user.name}_updated"
      user.save

      mail_count.should == 1
    end

    it "should send email about block user" do
      user = create :user

      clear_prepare_data

      Users::BlockContext.new(@user, user).execute

      mail_count.should == 1
    end

    it "should send email about self key add" do
      user = create :user

      clear_prepare_data

      create :key, user: user

      mail_count.should == 1
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

      clear_prepare_data
    end

    describe "Push Events" do
      it "should send email with summary push info "  do
        clear_prepare_data

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        mail_count.should == 1
      end
    end

    describe "Push Events with create branch" do
      it "should send email with created branch push info "  do
        @oldrev = '0000000000000000000000000000000000000000'

        clear_prepare_data

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        mail_count.should == 1
      end
    end

    describe "Push Events with create branch" do
      it "should send email with created tag push info "  do
        @oldrev = '0000000000000000000000000000000000000000'
        @ref = 'refs/tags/v2.2.0'

        clear_prepare_data

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        mail_count.should == 1
      end

    end

    describe "Push Events with create branch" do
      it "should send email with delete branch push info "  do
        @newrev = '0000000000000000000000000000000000000000'

        clear_prepare_data

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        mail_count.should == 1
      end
    end

    describe "Push Events with create branch" do
      it "should send email with delete tag push info "  do
        @newrev = '0000000000000000000000000000000000000000'
        @ref = 'refs/tags/v2.2.0'

        clear_prepare_data

        @service.execute(@project, @another_user, @oldrev, @newrev, @ref)

        mail_count.should == 1
      end

    end
  end
end
