require 'spec_helper'

describe Gitlab::Event::Factory do
  it "should build unsaved events on action" do
    Gitlab::Event::Factory.should respond_to :build
  end

  it "should create events from action" do
    Gitlab::Event::Factory.should respond_to :create_events
  end

  before do
    @user = create :user
    RequestStore.store[:current_user] = @user
  end

  #
  # Issue events
  #

  describe "Issue events" do
    before do
      ActiveRecord::Base.observers.disable :all
      #Issue.observers.enable :activity_observer

      @project = create :project, creator: @user
    end

    it "should build unsaved events on :created action for Issue" do
      @issue = create(:issue, project: @project)

      @action = 'gitlab.created.issue'
      @data = {source: @issue, user: @user, data: @issue}
      @events = Gitlab::Event::Factory.build(@action, @data)

      @events.should be_kind_of Array
      @events.should_not be_blank

      @events.each do |event|
        event.should_not be_persisted
      end
    end

    it "should build events from hash" do
      @issue = create(:issue, project: @project)
      #@old_events = Event.with_source(@issue)
      Event.with_source(@issue).destroy_all

      @action = 'gitlab.created.issue'
      @data = {source: @issue, user: @user, data: @issue}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@issue)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      # TODO. Check
      #@self_targeted_events = @current_events.with_target(@issue)
      #@self_targeted_events.should_not be_blank

      #@targeted_events = @current_events.with_target(@project)
      #@targeted_events.should_not be_blank
    end

    it "should build events from hash" do
      @issue = create(:issue, project: @project)

      @issue.title = "#{@issue.title}_updated"
      @issue.assignee = User.first
      @issue.save

      Event.with_source(@issue).destroy_all

      @action = 'gitlab.updated.issue'
      @data = {source: @issue, user: @user, data: @issue}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      #@current_events = Event.with_source(@issue)
      #@current_events.count.should be > 0
      #@current_events.count.should == @events.count
      #@current_events.count.should == 1 # Only update Issue.

      #@self_targeted_events = @current_events.with_target(@issue)
      #@self_targeted_events.should_not be_blank

      #@targeted_events = @current_events.with_target(@project)
      #@targeted_events.should be_blank
    end

    it "should build events from new issue note" do
      @issue = create(:issue, project: @project)
      @note = create(:note, noteable: @issue, project: @project)

      Event.with_source(@note).destroy_all

      @action = 'gitlab.created.note'
      @data = {source: @note, user: @user, data: @note}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@note)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@note)
      @self_targeted_events.should_not be_blank

      @issue_targeted_events = @current_events.with_target(@issue)
      @issue_targeted_events.should_not be_blank

      @project_targeted_events = @current_events.with_target(@project)
      @project_targeted_events.should_not be_blank
      @project_targeted_events.count.should == 1
      @project_targeted_events.first.action.to_sym.should == :commented_issue
    end
  end

  #
  # User events
  #

  describe "User events" do
    before do
      @user = create :user
      @another_user = create :user
      @project = create :project, creator: @user
      @team = create :team, creator: @another_user

      ActiveRecord::Base.observers.disable :all
      #User.observers.enable :activity_observer
    end

    it "should build User events with create" do
      @user = create(:user)

      Event.with_source(@user).destroy_all

      @action = 'gitlab.created.user'
      @data = {source: @user, user: @user, data: @user}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user)
      @self_targeted_events.should_not be_blank
    end

    it "should build User events with update" do
      @user.name = "#{@user.name}_updated"
      @user.save

      Event.with_source(@user).destroy_all

      @action = 'gitlab.updated.user'
      @data = {source: @user, user: @user, data: @user}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user)
      @self_targeted_events.should_not be_blank
    end

    it "should build User events with create users_project" do
      @project.team << [@user, :master]
      @users_project = UsersProject.find_by_user_id_and_project_id(@user, @project)

      Event.with_source(@users_project).destroy_all

      @action = 'gitlab.created.users_project'
      @data = {source: @users_project, user: @user, data: @users_project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@users_project)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@users_project)
      @self_targeted_events.should_not be_blank

      @user_targeted_events = @current_events.with_target(@user)
      @user_targeted_events.should_not be_blank
    end

    it "should build User events with update users_project" do
      @project.team << [@user, :master]
      @users_project = UsersProject.find_by_user_id_and_project_id(@user, @project)

      @users_project.project_access = UsersProject::DEVELOPER
      @users_project.save

      Event.with_source(@users_project).destroy_all

      @action = 'gitlab.updated.users_project'
      @data = {source: @users_project, user: @user, data: @users_project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@users_project)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@users_project)
      @self_targeted_events.should_not be_blank

      @user_targeted_events = @current_events.with_target(@user)
      @user_targeted_events.should_not be_blank
    end

    it "should build User events with remove users_project" do
      @project.team << [@user, :master]
      @users_project = UsersProject.find_by_user_id_and_project_id(@user, @project)

      @users_project.destroy

      Event.with_source(@users_project).destroy_all

      @action = 'gitlab.deleted.users_project'
      @data = {source: @users_project, user: @user, data: @users_project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@users_project)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@users_project)
      @self_targeted_events.should_not be_blank

      @user_targeted_events = @current_events.with_target(@user)
      @user_targeted_events.should_not be_blank
    end

    it "should build User events with create team_user_relationship" do

      add_users_with_role([@user], Gitlab::Access::MASTER)

      @team_user_relationship = TeamUserRelationship.find_by_user_id_and_team_id(@user, @team)

      Event.with_source(@team_user_relationship).destroy_all

      @action = 'gitlab.created.team_user_relationship'
      @data = {source: @team_user_relationship, user: @user, data: @team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_user_relationship)
      @self_targeted_events.should_not be_blank

      @user_targeted_events = @current_events.with_target(@user)
      @user_targeted_events.should_not be_blank
    end

    it "should build User events with update team_user_relationship" do
      add_users_with_role([@user], Gitlab::Access::MASTER)

      @team_user_relationship = TeamUserRelationship.find_by_user_id_and_team_id(@user, @team)

      @team_user_relationship.team_access = UsersProject::DEVELOPER
      @team_user_relationship.save

      Event.with_source(@team_user_relationship).destroy_all

      @action = 'gitlab.updated.team_user_relationship'
      @data = {source: @team_user_relationship, user: @user, data: @team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_user_relationship)
      @self_targeted_events.should_not be_blank

      @user_targeted_events = @current_events.with_target(@user)
      @user_targeted_events.should_not be_blank
    end

    it "should build User events with remove team_user_relationship" do
      add_users_with_role([@user], Gitlab::Access::MASTER)

      @team_user_relationship = TeamUserRelationship.find_by_user_id_and_team_id(@user, @team)

      @team_user_relationship.destroy

      Event.with_source(@team_user_relationship).destroy_all

      @action = 'gitlab.deleted.team_user_relationship'
      @data = {source: @team_user_relationship, user: @user, data: @team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_user_relationship)
      @self_targeted_events.should_not be_blank

      @user_targeted_events = @current_events.with_target(@user)
      @user_targeted_events.should_not be_blank
    end

    it "should build User events with create key" do
      @key = create(:key, user: @user)

      Event.with_source(@key).destroy_all

      @action = 'gitlab.created.key'
      @data = {source: @key, user: @user, data: @key}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@key)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@key)
      @self_targeted_events.should_not be_blank

      @user_targeted_events = @current_events.with_target(@user)
      @user_targeted_events.should_not be_blank
    end

    it "should build User events with update key" do
      @key = create(:key, user: @user)
      @key.title = "#{@key.title}_updated"
      @key.save

      Event.with_source(@key).destroy_all

      @action = 'gitlab.updated.key'
      @data = {source: @key, user: @user, data: @key}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@key)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user)
      @self_targeted_events.should_not be_blank

      @user_targeted_events = @current_events.with_target(@user)
      @user_targeted_events.should_not be_blank
    end

    it "should build User events with remove key" do
      @key = create(:key, user: @user)
      @key.destroy

      Event.with_source(@key).destroy_all

      @action = 'gitlab.deleted.key'
      @data = {source: @key, user: @user, data: @key}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@key)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@key)
      @self_targeted_events.should_not be_blank

      @user_targeted_events = @current_events.with_target(@key)
      @user_targeted_events.should_not be_blank
    end

    it "should build User events with destroy" do
      @user.destroy

      Event.with_source(@user).destroy_all

      @action = 'gitlab.deleted.user'
      @data = {source: @user, user: @user, data: @user}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user)
      @self_targeted_events.should_not be_blank
    end
    # TODO.
    # Add tests with Issue, MergeRequest, Milestone, Note, ProjectHook, ProtectedBranch, Service, Snippet
    # All models, which contain User
  end

  describe "Group events" do
    before do
      @user = create :user
      @group = create(:group, owner: @user)

      ActiveRecord::Base.observers.disable :all
      #Group.observers.enable :activity_observer
    end

    it "should build Group events with create" do
      @group = create(:group, owner: @user)
      Event.with_source(@group).destroy_all

      @action = 'gitlab.created.group'
      @data = {source: @group, user: @user, data: @group}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@group)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@group)
      @self_targeted_events.should_not be_blank
    end

    it "should build Group events with update" do
      @group.name = "#{@group.name}_updated"
      @group.save

      Event.with_source(@group).destroy_all

      @action = 'gitlab.updated.group'
      @data = {source: @group, user: @user, data: @group}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@group)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@group)
      @self_targeted_events.should_not be_blank
    end

    it "should build Group events with create project" do
      @project = create(:project, creator: @user, group: @group)

      Event.with_source(@project).destroy_all

      @action = 'gitlab.created.project'
      @data = {source: @project, user: @user, data: @project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@project)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@project)
      @self_targeted_events.should_not be_blank

      @group_targeted_events = @current_events.with_target(@group)
      @group_targeted_events.should_not be_blank
    end

    it "should build Group events with update project" do
      @project = create(:project, creator: @user, group: @group)
      @project.name = "#{@project.name}_updated"
      @project.save

      Event.with_source(@project).destroy_all

      @action = 'gitlab.updated.project'
      @data = {source: @project, user: @user, data: @project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      # TODO. Check
      #@current_events = Event.with_source(@project)

      #@current_events.count.should be > 0
      #@current_events.count.should == @events.count

      #@self_targeted_events = @current_events.with_target(@project)
      #@self_targeted_events.should_not be_blank

      #@group_targeted_events = @current_events.with_target(@group)
      #@group_targeted_events.should be_blank # We only update project, No moving
    end

    it "should build Group events with remove project" do
      @project = create(:project, creator: @user, group: @group)
      @project.destroy

      Event.with_source(@project).destroy_all

      @action = 'gitlab.deleted.project'
      @data = {source: @project, user: @user, data: @project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@project)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@project)
      @self_targeted_events.should_not be_blank

      @group_targeted_events = @current_events.with_target(@group)
      @group_targeted_events.should_not be_blank
    end

    it "should build Group events with destroy" do
      @group.destroy

      Event.with_source(@group).destroy_all

      @action = 'gitlab.deleted.group'
      @data = {source: @group, user: @user, data: @group}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@group)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@group)
      @self_targeted_events.should_not be_blank
    end
  end

  #
  # MergeRequest events
  #

  describe "MergeRequest events" do
    before do
      @user = create :user

      ActiveRecord::Base.observers.disable :all
      #MergeRequest.observers.enable :activity_observer

      @project = create :project, creator: @user
    end

    it "should build MergeRequest events for :create" do
      @merge_request = create :merge_request, source_project: @project, target_project: @project
      Event.with_source(@merge_request).destroy_all

      @action = 'gitlab.created.merge_request'
      @data = {source: @merge_request, user: @user, data: @merge_request}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@merge_request)

      # TODO. Check
      #@current_events.count.should be > 0
      #@current_events.count.should == @events.count

      #@self_targeted_events = @current_events.with_target(@merge_request)
      #@self_targeted_events.should_not be_blank

      #@targeted_events = @current_events.with_target(@project)
      #@targeted_events.should_not be_blank
    end

    it "should build MergeRequest events for Update" do
      @merge_request = create :merge_request, source_project: @project, target_project: @project

      @merge_request.title = "#{@merge_request.title}_updated"
      @merge_request.save

      Event.with_source(@merge_request).destroy_all

      @action = 'gitlab.updated.merge_request'
      @data = {source: @merge_request, user: @user, data: @merge_request}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      # TODO. Check
     # @current_events = Event.with_source(@merge_request)
      #@current_events.count.should be > 0
      #@current_events.count.should == @events.count
      #@current_events.count.should == 1 # Only update MergeRequest.

      #@self_targeted_events = @current_events.with_target(@merge_request)
      #@self_targeted_events.should_not be_blank

      #@targeted_events = @current_events.with_target(@project)
     # @targeted_events.should be_blank
    end

    it "should build events from new merge_request note" do
      @merge_request = create :merge_request, source_project: @project, target_project: @project
      @note = create(:note, noteable: @merge_request, project: @project)

      Event.with_source(@note).destroy_all

      @action = 'gitlab.created.note'
      @data = {source: @note, user: @user, data: @note}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@note)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@note)
      @self_targeted_events.should_not be_blank

      @merge_request_targeted_events = @current_events.with_target(@merge_request)
      @merge_request_targeted_events.should_not be_blank

      @project_targeted_events = @current_events.with_target(@project)
      @project_targeted_events.should_not be_blank
      @project_targeted_events.count.should == 1
      @project_targeted_events.first.action.to_sym.should == :commented_merge_request
    end
  end

  #
  # Team Events
  #

  describe "UsserTeam Events" do
    before do
      @user = create :user

      ActiveRecord::Base.observers.disable :all
      #Team.observers.enable :activity_observer

      @project = create :project, creator: @user
      @team = create(:team, creator: @user)
    end

    it "should build Team events for :create" do
      @team = create(:team, creator: @user)
      Event.with_source(@team).destroy_all

      @action = 'gitlab.created.team'
      @data = {source: @team, user: @user, data: @team}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team)
      @self_targeted_events.should_not be_blank
    end

    it "should build Team events for Update" do
      @team = create(:team, creator: @user)

      @team.name = "#{@team.name}_updated"
      @team.save

      Event.with_source(@team).destroy_all

      @action = 'gitlab.updated.team'
      @data = {source: @team, user: @user, data: @team}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team)
      @current_events.count.should be > 0
      @current_events.count.should == @events.count
      @current_events.count.should == 1 # Only update Team.

      @self_targeted_events = @current_events.with_target(@team)
      @self_targeted_events.should_not be_blank
    end

    it "should build User events with create team_user_relationship" do
      add_users_with_role([@user], Gitlab::Access::MASTER)

      @team_user_relationship = TeamUserRelationship.find_by_user_id_and_team_id(@user, @team)

      Event.with_source(@team_user_relationship).destroy_all

      @action = 'gitlab.created.team_user_relationship'
      @data = {source: @team_user_relationship, user: @user, data: @team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_user_relationship)
      @self_targeted_events.should_not be_blank

      @team_targeted_events = @current_events.with_target(@team)
      @team_targeted_events.should_not be_blank
    end

    it "should build User events with update team_user_relationship" do
      add_users_with_role([@user], Gitlab::Access::MASTER)

      @team_user_relationship = TeamUserRelationship.find_by_user_id_and_team_id(@user, @team)

      @team_user_relationship.team_access = UsersProject::DEVELOPER
      @team_user_relationship.save

      Event.with_source(@team_user_relationship).destroy_all

      @action = 'gitlab.updated.team_user_relationship'
      @data = {source: @team_user_relationship, user: @user, data: @team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_user_relationship)
      @self_targeted_events.should_not be_blank

      @team_targeted_events = @current_events.with_target(@team)
      @team_targeted_events.should_not be_blank
    end

    it "should build User events with remove team_user_relationship" do
      add_users_with_role([@user], Gitlab::Access::MASTER)

      @team_user_relationship = TeamUserRelationship.find_by_user_id_and_team_id(@user, @team)

      @team_user_relationship.destroy

      Event.with_source(@team_user_relationship).destroy_all

      @action = 'gitlab.deleted.team_user_relationship'
      @data = {source: @team_user_relationship, user: @user, data: @team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_user_relationship)
      @self_targeted_events.should_not be_blank

      @team_targeted_events = @current_events.with_target(@team)
      @team_targeted_events.should_not be_blank
    end

    it "should build User events with create team_project_relationship" do
      Teams::Projects::CreateRelationContext.new(@user, @team, {project_ids: "#{@project.id}"}).execute

      @team_project_relationship = TeamProjectRelationship.find_by_project_id_and_team_id(@project, @team)

      Event.with_source(@team_project_relationship).destroy_all

      @action = 'gitlab.created.team_project_relationship'
      @data = {source: @team_project_relationship, user: @user, data: @team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_project_relationship)
      @self_targeted_events.should_not be_blank

      @team_targeted_events = @current_events.with_target(@team)
      @team_targeted_events.should_not be_blank
    end

    it "should build User events with update team_project_relationship" do
      Teams::Projects::CreateRelationContext.new(@user, @team, {project_ids: "#{@project.id}"}).execute

      @team_project_relationship = TeamProjectRelationship.find_by_project_id_and_team_id(@project, @team)

      Event.with_source(@team_project_relationship).destroy_all

      @action = 'gitlab.updated.team_project_relationship'
      @data = {source: @team_project_relationship, user: @user, data: @team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_project_relationship)
      @self_targeted_events.should_not be_blank

      @team_targeted_events = @current_events.with_target(@team)
      @team_targeted_events.should_not be_blank
    end

    it "should build User events with remove team_project_relationship" do
      Teams::Projects::CreateRelationContext.new(@user, @team, {project_ids: "#{@project.id}"}).execute

      @team_project_relationship = TeamProjectRelationship.find_by_project_id_and_team_id(@project, @team)

      @team_project_relationship.destroy

      Event.with_source(@team_project_relationship).destroy_all

      @action = 'gitlab.deleted.team_project_relationship'
      @data = {source: @team_project_relationship, user: @user, data: @team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_project_relationship)
      @self_targeted_events.should_not be_blank

      @team_targeted_events = @current_events.with_target(@team)
      @team_targeted_events.should_not be_blank
    end

    it "should build Team events for Deleted" do
      @team = create(:team, creator: @user)
      @team.destroy

      Event.with_source(@team).destroy_all

      @action = 'gitlab.updated.team'
      @data = {source: @team, user: @user, data: @team}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team)
      @current_events.count.should be > 0
      @current_events.count.should == @events.count
      @current_events.count.should == 1 # Only update Team.

      @self_targeted_events = @current_events.with_target(@team)
      @self_targeted_events.should_not be_blank
    end
  end

  #
  # Project Events
  #

  describe "Project Events" do
    before do
      @user = create :user

      ActiveRecord::Base.observers.disable :all
      #Project.observers.enable :activity_observer

      @project = create :project, creator: @user
      @team = create(:team, creator: @user)
    end

    it "should build Project events for :create" do
      @project = create(:project, creator: @user)
      Event.with_source(@project).destroy_all

      @action = 'gitlab.created.project'
      @data = {source: @project, user: @user, data: @project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@project)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@project)
      @self_targeted_events.should_not be_blank
    end

    it "should build Project events for Update" do
      @project.name = "#{@project.name}_updated"
      @project.save

      Event.with_source(@project).destroy_all

      @action = 'gitlab.updated.project'
      @data = {source: @project, user: @user, data: @project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      # TODO. Check
      #@current_events = Event.with_source(@project)
      #@current_events.count.should be > 0
      #@current_events.count.should == @events.count
      #@current_events.count.should == 1 # Only update Project.

      #@self_targeted_events = @current_events.with_target(@project)
      #@self_targeted_events.should_not be_blank
    end

    it "should build User events with create team_project_relationship" do
      Teams::Projects::CreateRelationContext.new(@user, @team, {project_ids: "#{@project.id}"}).execute

      Event.with_source(@team_project_relationship).destroy_all

      @action = 'gitlab.created.team_project_relationship'
      @data = {source: @team_project_relationship, user: @user, data: @team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_project_relationship)
      @self_targeted_events.should_not be_blank

      @project_targeted_events = @current_events.with_target(@project)
      @project_targeted_events.should_not be_blank
    end

    it "should build User events with update team_project_relationship" do
      Teams::Projects::CreateRelationContext.new(@user, @team, {project_ids: "#{@project.id}"}).execute

      Event.with_source(@team_project_relationship).destroy_all

      @action = 'gitlab.updated.team_project_relationship'
      @data = {source: @team_project_relationship, user: @user, data: @team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_project_relationship)
      @self_targeted_events.should_not be_blank

      @project_targeted_events = @current_events.with_target(@project)
      @project_targeted_events.should_not be_blank
    end

    it "should build User events with remove team_project_relationship" do
      Teams::Projects::CreateRelationContext.new(@user, @team, {project_ids: "#{@project.id}"}).execute

      @team_project_relationship = TeamProjectRelationship.find_by_project_id_and_team_id(@project, @team)

      @team_project_relationship.destroy

      Event.with_source(@team_project_relationship).destroy_all

      @action = 'gitlab.deleted.team_project_relationship'
      @data = {source: @team_project_relationship, user: @user, data: @team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@team_project_relationship)
      @self_targeted_events.should_not be_blank

      @project_targeted_events = @current_events.with_target(@project)
      @project_targeted_events.should_not be_blank
    end

    it "should build User events with create users_project" do
      @project.team << [@user, :master]
      @users_project = UsersProject.find_by_user_id_and_project_id(@user, @project)

      Event.with_source(@users_project).destroy_all

      @action = 'gitlab.created.users_project'
      @data = {source: @users_project, user: @user, data: @users_project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@users_project)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@users_project)
      @self_targeted_events.should_not be_blank

      @project_targeted_events = @current_events.with_target(@project)
      @project_targeted_events.should_not be_blank
    end

    it "should build User events with update users_project" do
      @project.team << [@user, :master]
      @users_project = UsersProject.find_by_user_id_and_project_id(@user, @project)

      @users_project.project_access = UsersProject::DEVELOPER
      @users_project.save

      Event.with_source(@users_project).destroy_all

      @action = 'gitlab.updated.users_project'
      @data = {source: @users_project, user: @user, data: @users_project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@users_project)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user)
      @self_targeted_events.should_not be_blank

      @project_targeted_events = @current_events.with_target(@project)
      @project_targeted_events.should_not be_blank
    end

    it "should build User events with remove users_project" do
      @project.team << [@user, :master]
      @users_project = UsersProject.find_by_user_id_and_project_id(@user, @project)

      @users_project.destroy

      Event.with_source(@users_project).destroy_all

      @action = 'gitlab.deleted.users_project'
      @data = {source: @users_project, user: @user, data: @users_project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@users_project)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@users_project)
      @self_targeted_events.should_not be_blank

      @project_targeted_events = @current_events.with_target(@project)
      @project_targeted_events.should_not be_blank
    end

    it "should build Project events for Deleted" do
      @project = create(:project, creator: @user)
      @project.destroy

      Event.with_source(@project).destroy_all

      @action = 'gitlab.updated.project'
      @data = {source: @project, user: @user, data: @project}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      # TODO. Check
      #@current_events = Event.with_source(@project)
      #@current_events.count.should be > 0
      #@current_events.count.should == @events.count
      #@current_events.count.should == 1 # Only update Project.

      #@self_targeted_events = @current_events.with_target(@project)
      #@self_targeted_events.should_not be_blank
    end

    # TODO.
    # Add tests with Issue, MergeRequest, Milestone, Note, ProjectHook, ProtectedBranch, Service, Snippet
  end

  describe "Push actions" do

    before do
      @user = create :user
      @project = create :project_with_code, creator: @user
      @service = GitPushService.new
      @oldrev = 'b98a310def241a6fd9c9a9a3e7934c48e498fe81'
      @newrev = 'b19a04f53caeebf4fe5ec2327cb83e9253dc91bb'
      @ref = 'refs/heads/master'
    end

    describe "Push Events" do
      before do
        @service.execute(@project, @user, @oldrev, @newrev, @ref)
        @push_data = @service.push_data

        Event.with_target(@project).with_push.destroy_all

        @action = 'gitlab.pushed.push_summary'
        @data = { source: "Push_summary", user: @user, data: { project_id: @project.id, push_data: @push_data } }

        @events = Gitlab::Event::Factory.build(@action, @data)
        Gitlab::Event::Factory.create_events(@action, @data)

        @current_events = Event.with_target(@project).with_push
      end

      it { @current_events.should_not be_nil }
    end

  end

  def add_users_with_role(users, role)
    @user_ids = users.map{ |u| u.id }.join(",")
    @params = {
      user_ids: @user_ids,
      team_access: role
    }

    Teams::Users::CreateRelationContext.new(@user, @team, @params).execute
  end
end
