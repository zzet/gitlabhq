require 'spec_helper'

describe ActivityObserver do

  def notification_data_for(notification)
    test_info = {}
    subscription = ActiveSupport::Notifications.subscribe notification do |name, start, finish, id, _payload|
      test_info[:name] = name
      test_info[:data] = _payload
    end

    yield

    ActiveSupport::Notifications.unsubscribe(subscription)

    return test_info
  end


  #
  # Observe Key changes
  #

  describe "Key events" do
    before do
      ActiveRecord::Base.observers.disable :all
      Key.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @key = create(:key, user: @user)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::Key
    end

    it "Should generate :updated event" do
      @key = create(:key, user: @user)

      data = notification_data_for(/gitlab/) do
        @key.title = "#{@key.title}_updated"
        @key.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::Key
    end

    it "Should generate :deleted event" do
      @key = create(:key, user: @user)

      data = notification_data_for(/gitlab/) do
        @key.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::Key
    end

  end

  #
  # Observe Issue changes
  #

  describe "Issue events" do
    before do
      ActiveRecord::Base.observers.disable :all
      Issue.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @issue = create(:issue, project: @project)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::Issue
    end

    it "Should generate :updated event" do
      @issue = create(:issue, project: @project)

      data = notification_data_for(/gitlab/) do
        @issue.title = "#{@issue.title}_updated"
        @issue.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::Issue
    end

    it "Should generate :deleted event" do
      @issue = create(:issue, project: @project)

      data = notification_data_for(/gitlab/) do
        @issue.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::Issue
    end

  end


  #
  # Observe MergeRequest changes
  #

  describe "MergeRequest events" do
    before do
      ActiveRecord::Base.observers.disable :all
      MergeRequest.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @merge_request = create(:merge_request, project: @project)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::MergeRequest
    end

    it "Should generate :updated event" do
      @merge_request = create(:merge_request, project: @project)

      data = notification_data_for(/gitlab/) do
        @merge_request.title = "#{@merge_request.title}_updated"
        @merge_request.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::MergeRequest
    end

    it "Should generate :deleted event" do
      @merge_request = create(:merge_request, project: @project)

      data = notification_data_for(/gitlab/) do
        @merge_request.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::MergeRequest
    end

  end


  #
  # Observe Milestone changes
  #

  describe "Milestone events" do
    before do
      ActiveRecord::Base.observers.disable :all
      Milestone.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @milestone = create(:milestone, project: @project)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::Milestone
    end

    it "Should generate :updated event" do
      @milestone = create(:milestone, project: @project)

      data = notification_data_for(/gitlab/) do
        @milestone.title = "#{@milestone.title}_updated"
        @milestone.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::Milestone
    end

    it "Should generate :deleted event" do
      @milestone = create(:milestone, project: @project)

      data = notification_data_for(/gitlab/) do
        @milestone.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::Milestone
    end

  end


  #
  # Observe Group changes
  #

  describe "Group events" do
    before do
      ActiveRecord::Base.observers.disable :all
      Group.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @group = create(:group, owner: @user)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::Group
    end

    it "Should generate :updated event" do
      @group = create(:group, owner: @user)

      data = notification_data_for(/gitlab/) do
        @group.name = "#{@group.name}_updated"
        @group.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::Group
    end

    it "Should generate :deleted event" do
      @group = create(:group, owner: @user)

      data = notification_data_for(/gitlab/) do
        @group.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::Group
    end

  end

  #
  # Observe Note changes
  #

  describe "Note events" do
    before do
      ActiveRecord::Base.observers.disable :all
      Note.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @note = create(:note, project: @project)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::Note
    end

    it "Should generate :updated event" do
      @note = create(:note, project: @project)

      data = notification_data_for(/gitlab/) do
        @note.note = "#{@note.note}_updated"
        @note.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::Note
    end

    it "Should generate :deleted event" do
      @note = create(:note, project: @project)

      data = notification_data_for(/gitlab/) do
        @note.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::Note
    end
  end

  #
  # Observe Project changes
  #

  describe "Project events" do
    before do
      ActiveRecord::Base.observers.disable :all
      Project.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @project = create(:project)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::Project
    end

    it "Should generate :updated event" do
      @project = create(:project)

      data = notification_data_for(/gitlab/) do
        @project.name = "#{@project.name}_updated"
        @project.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::Project
    end

    it "Should generate :deleted event" do
      @project = create(:project)

      data = notification_data_for(/gitlab/) do
        @project.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::Project
    end

  end


  #
  # Observe ProtectedBranch changes
  #

  describe "ProtectedBranch events" do
    before do
      ActiveRecord::Base.observers.disable :all
      ProtectedBranch.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @protected_branch = create(:protected_branch, project: @project)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::ProtectedBranch
    end

    it "Should generate :updated event" do
      @protected_branch = create(:protected_branch, project: @project)

      data = notification_data_for(/gitlab/) do
        @protected_branch.name = "#{@protected_branch.name}_updated"
        @protected_branch.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::ProtectedBranch
    end

    it "Should generate :deleted event" do
      @protected_branch = create(:protected_branch, project: @project)

      data = notification_data_for(/gitlab/) do
        @protected_branch.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::ProtectedBranch
    end

  end


  #
  # Observe Service changes
  #

  describe "Service events" do
    before do
      ActiveRecord::Base.observers.disable :all
      Service.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @service = create(:service)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::Service
    end

    it "Should generate :updated event" do
      @service = create(:service)

      data = notification_data_for(/gitlab/) do
        @service.title = "#{@service.title}_updated"
        @service.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::Service
    end

    it "Should generate :deleted event" do
      @service = create(:service)

      data = notification_data_for(/gitlab/) do
        @service.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::Service
    end

  end


  #
  # Observe Snippet changes
  #

  describe "Snippet events" do
    before do
      ActiveRecord::Base.observers.disable :all
      Snippet.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @snippet = create(:snippet, project: @project)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::Snippet
    end

    it "Should generate :updated event" do
      @snippet = create(:snippet, project: @project)

      data = notification_data_for(/gitlab/) do
        @snippet.title = "#{@snippet.title}_updated"
        @snippet.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::Snippet
    end

    it "Should generate :deleted event" do
      @snippet = create(:snippet, project: @project)

      data = notification_data_for(/gitlab/) do
        @snippet.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::Snippet
    end

  end


  #
  # Observe User changes
  #

  describe "User events" do
    before do
      ActiveRecord::Base.observers.disable :all
      User.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @user = create(:user)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::User
    end

    it "Should generate :updated event" do
      @user = create(:user)

      data = notification_data_for(/gitlab/) do
        @user.name = "#{@user.name}_updated"
        @user.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::User
    end

    it "Should generate :deleted event" do
      @user = create(:user)

      data = notification_data_for(/gitlab/) do
        @user.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::User
    end

  end


  #
  # Observe UserTeam changes
  #

  describe "UserTeam events" do
    before do
      ActiveRecord::Base.observers.disable :all
      UserTeam.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @user_team = create(:user_team, owner: @user)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::UserTeam
    end

    it "Should generate :updated event" do
      @user_team = create(:user_team, owner: @user)

      data = notification_data_for(/gitlab/) do
        @user_team.name = "#{@user_team.name}_updated"
        @user_team.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::UserTeam
    end

    it "Should generate :deleted event" do
      @user_team = create(:user_team, owner: @user)

      data = notification_data_for(/gitlab/) do
        @user_team.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::UserTeam
    end

  end


  #
  # Observe UserTeamProjectRelationship changes
  #

  describe "UserTeamProjectRelationship events" do
    before do
      ActiveRecord::Base.observers.disable :all
      UserTeamProjectRelationship.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @user_team_project_relationship = create(:user_team_project_relationship, project: @project)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::UserTeamProjectRelationship
    end

    it "Should generate :updated event" do
      @user_team_project_relationship = create(:user_team_project_relationship, project: @project)

      data = notification_data_for(/gitlab/) do
        @user_team_project_relationship.greatest_access = (UsersProject.access_roles.values - [@user_team_project_relationship.greatest_access]).first
        @user_team_project_relationship.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::UserTeamProjectRelationship
    end

    it "Should generate :deleted event" do
      @user_team_project_relationship = create(:user_team_project_relationship, project: @project)

      data = notification_data_for(/gitlab/) do
        @user_team_project_relationship.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::UserTeamProjectRelationship
    end

  end


  #
  # Observe UserTeamUserRelationship changes
  #

  describe "UserTeamUserRelationship events" do
    before do
      ActiveRecord::Base.observers.disable :all
      UserTeamUserRelationship.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @user_team_user_relationship = create(:user_team_user_relationship, user: @user)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::UserTeamUserRelationship
    end

    it "Should generate :updated event" do
      @user_team_user_relationship = create(:user_team_user_relationship, user: @user)

      data = notification_data_for(/gitlab/) do
        @user_team_user_relationship.permission = (UsersProject.access_roles.values - [@user_team_user_relationship.permission]).first
        @user_team_user_relationship.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::UserTeamUserRelationship
    end

    it "Should generate :deleted event" do
      @user_team_user_relationship = create(:user_team_user_relationship, user: @user)

      data = notification_data_for(/gitlab/) do
        @user_team_user_relationship.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::UserTeamUserRelationship
    end

  end

  #
  # Observe UsersProject changes
  #

  describe "UsersProject events" do
    before do
      ActiveRecord::Base.observers.disable :all
      UsersProject.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @users_project = create(:users_project, user: @user, project: @project)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::UsersProject
    end

    it "Should generate :updated event" do
      @users_project = create(:users_project, user: @user, project: @project)

      data = notification_data_for(/gitlab/) do
        @users_project.project_access = (UsersProject.access_roles.values - [@users_project.project_access]).first
        @users_project.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::UsersProject
    end

    it "Should generate :deleted event" do
      @users_project = create(:users_project, user: @user, project: @project)

      data = notification_data_for(/gitlab/) do
        @users_project.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::UsersProject
    end

  end


  #
  # Observe ProjectHook changes
  #

  describe "ProjectHook events" do
    before do
      ActiveRecord::Base.observers.disable :all
      ProjectHook.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @project_hook = create(:project_hook, project: @project)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::ProjectHook
    end

    it "Should generate :updated event" do
      @project_hook = create(:project_hook, project: @project)

      data = notification_data_for(/gitlab/) do
        @project_hook.url = "#{@project_hook.url}/update"
        @project_hook.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::ProjectHook
    end

    it "Should generate :deleted event" do
      @project_hook = create(:project_hook, project: @project)

      data = notification_data_for(/gitlab/) do
        @project_hook.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::ProjectHook
    end

  end

  #
  # Observe SystemHook changes
  #

  describe "SystemHook events" do
    before do
      ActiveRecord::Base.observers.disable :all
      SystemHook.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @system_hook = create(:system_hook)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::SystemHook
    end

    it "Should generate :updated event" do
      @system_hook = create(:system_hook)

      data = notification_data_for(/gitlab/) do
        @system_hook.url = "#{@system_hook.url}/update"
        @system_hook.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::SystemHook
    end

    it "Should generate :deleted event" do
      @system_hook = create(:system_hook)

      data = notification_data_for(/gitlab/) do
        @system_hook.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::SystemHook
    end

  end


  #
  # Observe Wiki changes
  #

  describe "Wiki events" do
    before do
      ActiveRecord::Base.observers.disable :all
      Wiki.observers.enable :activity_observer

      @user = create :user
      Gitlab::Event::Notifications.current_user = @user

      @project = create :project, creator: @user
    end

    it "Should generate :created event" do

      data = notification_data_for(/gitlab/) do
        @wiki = create(:wiki, project: @project)
      end

      data[:name].should match(/created/)
      data[:data][:source].should be_kind_of ::Wiki
    end

    it "Should generate :updated event" do
      @wiki = create(:wiki, project: @project)

      data = notification_data_for(/gitlab/) do
        @wiki.title = "#{@wiki.title}_updated"
        @wiki.save
      end

      data[:name].should match(/updated/)
      data[:data][:source].should be_kind_of ::Wiki
    end

    it "Should generate :deleted event" do
      @wiki = create(:wiki, project: @project)

      data = notification_data_for(/gitlab/) do
        @wiki.destroy
      end

      data[:name].should match(/deleted/)
      data[:data][:source].should be_kind_of ::Wiki
    end

  end

end
