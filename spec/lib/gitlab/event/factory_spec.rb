require 'spec_helper'

describe Gitlab::Event::Factory do
  it "should build unsaved events on action" do
    Gitlab::Event::Factory.should respond_to :build
  end

  it "should create events from action" do
    Gitlab::Event::Factory.should respond_to :create_events
  end

  #
  # Issue events
  #

  describe "Issue events" do
    before do
      @user = create :user

      Gitlab::Event::Action.current_user = @user
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

      @self_targeted_events = @current_events.with_target(@issue)
      @self_targeted_events.should_not be_blank

      @targeted_events = @current_events.with_target(@project)
      @targeted_events.should_not be_blank
    end

    it "should build events from hash" do
      @issue = create(:issue, project: @project)

      @issue.title = "#{@issue.title}_updated"
      @issue.save

      Event.with_source(@issue).destroy_all

      @action = 'gitlab.updated.issue'
      @data = {source: @issue, user: @user, data: @issue}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@issue)
      @current_events.count.should be > 0
      @current_events.count.should == @events.count
      @current_events.count.should == 1 # Only update Issue.

      @self_targeted_events = @current_events.with_target(@issue)
      @self_targeted_events.should_not be_blank

      @targeted_events = @current_events.with_target(@project)
      @targeted_events.should be_blank
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
      @project_targeted_events.first.action.to_sym.should == :commented_related
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
      @user_team = create :user_team, owner: @another_user

      Gitlab::Event::Action.current_user = @user
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

    it "should build User events with create user_team_user_relationship" do
      @user_team.add_member @user, UsersProject::MASTER, false

      @user_team_user_relationship = UserTeamUserRelationship.find_by_user_id_and_user_team_id(@user, @user_team)

      Event.with_source(@user_team_user_relationship).destroy_all

      @action = 'gitlab.created.user_team_user_relationship'
      @data = {source: @user_team_user_relationship, user: @user, data: @user_team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_user_relationship)
      @self_targeted_events.should_not be_blank

      @user_targeted_events = @current_events.with_target(@user)
      @user_targeted_events.should_not be_blank
    end

    it "should build User events with update user_team_user_relationship" do
      @user_team.add_member @user, UsersProject::MASTER, false

      @user_team_user_relationship = UserTeamUserRelationship.find_by_user_id_and_user_team_id(@user, @user_team)

      @user_team_user_relationship.permission = UsersProject::DEVELOPER
      @user_team_user_relationship.save

      Event.with_source(@user_team_user_relationship).destroy_all

      @action = 'gitlab.updated.user_team_user_relationship'
      @data = {source: @user_team_user_relationship, user: @user, data: @user_team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_user_relationship)
      @self_targeted_events.should_not be_blank

      @user_targeted_events = @current_events.with_target(@user)
      @user_targeted_events.should_not be_blank
    end

    it "should build User events with remove user_team_user_relationship" do
      @user_team.add_member @user, UsersProject::MASTER, false

      @user_team_user_relationship = UserTeamUserRelationship.find_by_user_id_and_user_team_id(@user, @user_team)

      @user_team_user_relationship.destroy

      Event.with_source(@user_team_user_relationship).destroy_all

      @action = 'gitlab.deleted.user_team_user_relationship'
      @data = {source: @user_team_user_relationship, user: @user, data: @user_team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_user_relationship)
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

      Gitlab::Event::Action.current_user = @user
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

      @current_events = Event.with_source(@project)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@project)
      @self_targeted_events.should_not be_blank

      @group_targeted_events = @current_events.with_target(@group)
      @group_targeted_events.should be_blank # We only update project, No moving
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

      Gitlab::Event::Action.current_user = @user
      ActiveRecord::Base.observers.disable :all
      #MergeRequest.observers.enable :activity_observer

      @project = create :project, creator: @user
    end

    it "should build MergeRequest events for :create" do
      @merge_request = create(:merge_request, project: @project)
      Event.with_source(@merge_request).destroy_all

      @action = 'gitlab.created.merge_request'
      @data = {source: @merge_request, user: @user, data: @merge_request}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@merge_request)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@merge_request)
      @self_targeted_events.should_not be_blank

      @targeted_events = @current_events.with_target(@project)
      @targeted_events.should_not be_blank
    end

    it "should build MergeRequest events for Update" do
      @merge_request = create(:merge_request, project: @project)

      @merge_request.title = "#{@merge_request.title}_updated"
      @merge_request.save

      Event.with_source(@merge_request).destroy_all

      @action = 'gitlab.updated.merge_request'
      @data = {source: @merge_request, user: @user, data: @merge_request}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@merge_request)
      @current_events.count.should be > 0
      @current_events.count.should == @events.count
      @current_events.count.should == 1 # Only update MergeRequest.

      @self_targeted_events = @current_events.with_target(@merge_request)
      @self_targeted_events.should_not be_blank

      @targeted_events = @current_events.with_target(@project)
      @targeted_events.should be_blank
    end

    it "should build events from new merge_request note" do
      @merge_request = create(:merge_request, project: @project)
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
      @project_targeted_events.first.action.to_sym.should == :commented_related
    end
  end

  #
  # UserTeam Events
  #

  describe "UsserTeam Events" do
    before do
      @user = create :user

      Gitlab::Event::Action.current_user = @user
      ActiveRecord::Base.observers.disable :all
      #UserTeam.observers.enable :activity_observer

      @project = create :project, creator: @user
      @user_team = create(:user_team, owner: @user)
    end

    it "should build UserTeam events for :create" do
      @user_team = create(:user_team, owner: @user)
      Event.with_source(@user_team).destroy_all

      @action = 'gitlab.created.user_team'
      @data = {source: @user_team, user: @user, data: @user_team}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team)
      @self_targeted_events.should_not be_blank
    end

    it "should build UserTeam events for Update" do
      @user_team = create(:user_team, owner: @user)

      @user_team.name = "#{@user_team.name}_updated"
      @user_team.save

      Event.with_source(@user_team).destroy_all

      @action = 'gitlab.updated.user_team'
      @data = {source: @user_team, user: @user, data: @user_team}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team)
      @current_events.count.should be > 0
      @current_events.count.should == @events.count
      @current_events.count.should == 1 # Only update UserTeam.

      @self_targeted_events = @current_events.with_target(@user_team)
      @self_targeted_events.should_not be_blank
    end

    it "should build User events with create user_team_user_relationship" do
      @user_team.add_member @user, UsersProject::MASTER, false

      @user_team_user_relationship = UserTeamUserRelationship.find_by_user_id_and_user_team_id(@user, @user_team)

      Event.with_source(@user_team_user_relationship).destroy_all

      @action = 'gitlab.created.user_team_user_relationship'
      @data = {source: @user_team_user_relationship, user: @user, data: @user_team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_user_relationship)
      @self_targeted_events.should_not be_blank

      @user_team_targeted_events = @current_events.with_target(@user_team)
      @user_team_targeted_events.should_not be_blank
    end

    it "should build User events with update user_team_user_relationship" do
      @user_team.add_member @user, UsersProject::MASTER, false

      @user_team_user_relationship = UserTeamUserRelationship.find_by_user_id_and_user_team_id(@user, @user_team)

      @user_team_user_relationship.permission = UsersProject::DEVELOPER
      @user_team_user_relationship.save

      Event.with_source(@user_team_user_relationship).destroy_all

      @action = 'gitlab.updated.user_team_user_relationship'
      @data = {source: @user_team_user_relationship, user: @user, data: @user_team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_user_relationship)
      @self_targeted_events.should_not be_blank

      @user_team_targeted_events = @current_events.with_target(@user_team)
      @user_team_targeted_events.should_not be_blank
    end

    it "should build User events with remove user_team_user_relationship" do
      @user_team.add_member @user, UsersProject::MASTER, false

      @user_team_user_relationship = UserTeamUserRelationship.find_by_user_id_and_user_team_id(@user, @user_team)

      @user_team_user_relationship.destroy

      Event.with_source(@user_team_user_relationship).destroy_all

      @action = 'gitlab.deleted.user_team_user_relationship'
      @data = {source: @user_team_user_relationship, user: @user, data: @user_team_user_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_user_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_user_relationship)
      @self_targeted_events.should_not be_blank

      @user_team_targeted_events = @current_events.with_target(@user_team)
      @user_team_targeted_events.should_not be_blank
    end

    it "should build User events with create user_team_project_relationship" do
      @user_team.assign_to_project @project, UsersProject::MASTER

      @user_team_project_relationship = UserTeamProjectRelationship.find_by_project_id_and_user_team_id(@project, @user_team)

      Event.with_source(@user_team_project_relationship).destroy_all

      @action = 'gitlab.created.user_team_project_relationship'
      @data = {source: @user_team_project_relationship, user: @user, data: @user_team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_project_relationship)
      @self_targeted_events.should_not be_blank

      @user_team_targeted_events = @current_events.with_target(@user_team)
      @user_team_targeted_events.should_not be_blank
    end

    it "should build User events with update user_team_project_relationship" do
      @user_team.assign_to_project @project, UsersProject::MASTER

      @user_team_project_relationship = UserTeamProjectRelationship.find_by_project_id_and_user_team_id(@project, @user_team)

      @user_team_project_relationship.greatest_access = UsersProject::DEVELOPER
      @user_team_project_relationship.save

      Event.with_source(@user_team_project_relationship).destroy_all

      @action = 'gitlab.updated.user_team_project_relationship'
      @data = {source: @user_team_project_relationship, user: @user, data: @user_team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_project_relationship)
      @self_targeted_events.should_not be_blank

      @user_team_targeted_events = @current_events.with_target(@user_team)
      @user_team_targeted_events.should_not be_blank
    end

    it "should build User events with remove user_team_project_relationship" do
      @user_team.assign_to_project @project, UsersProject::MASTER

      @user_team_project_relationship = UserTeamProjectRelationship.find_by_project_id_and_user_team_id(@project, @user_team)

      @user_team_project_relationship.destroy

      Event.with_source(@user_team_project_relationship).destroy_all

      @action = 'gitlab.deleted.user_team_project_relationship'
      @data = {source: @user_team_project_relationship, user: @user, data: @user_team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_project_relationship)
      @self_targeted_events.should_not be_blank

      @user_team_targeted_events = @current_events.with_target(@user_team)
      @user_team_targeted_events.should_not be_blank
    end

    it "should build UserTeam events for Deleted" do
      @user_team = create(:user_team, owner: @user)
      @user_team.destroy

      Event.with_source(@user_team).destroy_all

      @action = 'gitlab.updated.user_team'
      @data = {source: @user_team, user: @user, data: @user_team}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team)
      @current_events.count.should be > 0
      @current_events.count.should == @events.count
      @current_events.count.should == 1 # Only update UserTeam.

      @self_targeted_events = @current_events.with_target(@user_team)
      @self_targeted_events.should_not be_blank
    end
  end

  #
  # Project Events
  #

  describe "Project Events" do
    before do
      @user = create :user

      Gitlab::Event::Action.current_user = @user
      ActiveRecord::Base.observers.disable :all
      #Project.observers.enable :activity_observer

      @project = create :project, creator: @user
      @user_team = create(:user_team, owner: @user)
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

      @current_events = Event.with_source(@project)
      @current_events.count.should be > 0
      @current_events.count.should == @events.count
      @current_events.count.should == 1 # Only update Project.

      @self_targeted_events = @current_events.with_target(@project)
      @self_targeted_events.should_not be_blank
    end

    it "should build User events with create user_team_project_relationship" do
      @user_team.assign_to_project @project, UsersProject::MASTER

      @user_team_project_relationship = UserTeamProjectRelationship.find_by_project_id_and_user_team_id(@project, @user_team)

      Event.with_source(@user_team_project_relationship).destroy_all

      @action = 'gitlab.created.user_team_project_relationship'
      @data = {source: @user_team_project_relationship, user: @user, data: @user_team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_project_relationship)
      @self_targeted_events.should_not be_blank

      @project_targeted_events = @current_events.with_target(@project)
      @project_targeted_events.should_not be_blank
    end

    it "should build User events with update user_team_project_relationship" do
      @user_team.assign_to_project @project, UsersProject::MASTER

      @user_team_project_relationship = UserTeamProjectRelationship.find_by_project_id_and_user_team_id(@project, @user_team)

      @user_team_project_relationship.greatest_access = UsersProject::DEVELOPER
      @user_team_project_relationship.save

      Event.with_source(@user_team_project_relationship).destroy_all

      @action = 'gitlab.updated.user_team_project_relationship'
      @data = {source: @user_team_project_relationship, user: @user, data: @user_team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_project_relationship)
      @self_targeted_events.should_not be_blank

      @project_targeted_events = @current_events.with_target(@project)
      @project_targeted_events.should_not be_blank
    end

    it "should build User events with remove user_team_project_relationship" do
      @user_team.assign_to_project @project, UsersProject::MASTER

      @user_team_project_relationship = UserTeamProjectRelationship.find_by_project_id_and_user_team_id(@project, @user_team)

      @user_team_project_relationship.destroy

      Event.with_source(@user_team_project_relationship).destroy_all

      @action = 'gitlab.deleted.user_team_project_relationship'
      @data = {source: @user_team_project_relationship, user: @user, data: @user_team_project_relationship}

      @events = Gitlab::Event::Factory.build(@action, @data)
      Gitlab::Event::Factory.create_events(@action, @data)

      @current_events = Event.with_source(@user_team_project_relationship)

      @current_events.count.should be > 0
      @current_events.count.should == @events.count

      @self_targeted_events = @current_events.with_target(@user_team_project_relationship)
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

      @current_events = Event.with_source(@project)
      @current_events.count.should be > 0
      @current_events.count.should == @events.count
      @current_events.count.should == 1 # Only update Project.

      @self_targeted_events = @current_events.with_target(@project)
      @self_targeted_events.should_not be_blank
    end

    # TODO.
    # Add tests with Issue, MergeRequest, Milestone, Note, ProjectHook, ProtectedBranch, Service, Snippet
  end

  describe "Push actions" do

    before do
      @user = create :user
      @project = create :project, creator: @user
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
end
