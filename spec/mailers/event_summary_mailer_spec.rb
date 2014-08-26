require "spec_helper"

describe EventSummaryMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  ITERATION_COUNT = 5
  EVENTS_SUMMARY_PERIODS = {
    daily:   [1.day,   Summaries::DailyWorker],
    weekly:  [1.week,  Summaries::WeeklyWorker],
    monthly: [1.month, Summaries::MonthlyWorker]
  }

  def clear_prepare_data
    Event.delete_all
    Event::Subscription::Notification.delete_all
    ActionMailer::Base.deliveries.clear
    EventHierarchyWorker.reset
    RequestStore.store[:borders] = []
  end

  def select_digest_mails(mails)
    mails.select{ |m| m.subject.match(/digest title/) }
  end

  def expected_mails_count(entities = [])
    EVENTS_SUMMARY_PERIODS.count + entities.inject(0) { |a, e| a += Event::Subscription.where(target_id: e.id, target_type: e.class.name).count }
  end

  def add_retry
    EVENTS_SUMMARY_PERIODS.each do |period, detail|
      Timecop.travel(detail[0]) do
        Resque.enqueue(detail[1])
      end
    end
  end

  def save_emails
    ActionMailer::Base.deliveries.each do |message|
      File.open("#{Rails.root}/tmp/#{Time.now.to_i}_#{rand(100)}.html", 'w+') do |file|
        file.write(message.body.raw_source)
      end
    end
  end

  def show_emails
    ActionMailer::Base.deliveries.each do |message|
      puts message.body.raw_source
    end
  end

  subject(:mails) { ActionMailer::Base.deliveries }

  def collect_events
    Gitlab::Event::Factory.unstub(:call)
    yield
    Gitlab::Event::Factory.stub(call: true)
  end

  before do
    ActiveRecord::Base.observers.enable(:user_observer) do
      @user = create :user, admin: true
      @another_user = create :user
      @commiter_user = create :user, { email: "dmitriy.zaporozhets@gmail.com" }
    end

    @user.create_notification_setting(brave: true)
    RequestStore.store[:current_user] = @another_user
    clear_prepare_data
    ActiveRecord::Base.observers.enable :all
  end

  let(:groups) {
    groups = []
    group = create :group, owner: @user
    groups << group

    clear_prepare_data

    groups
  }

  let(:projects) {
    projects = []
    groups.each do |group|
      5.times do
        project = create(:empty_project, creator: @user, namespace: group)
        project.team << [@another_user, Gitlab::Access::MASTER]
        projects << project
      end
    end

    clear_prepare_data

    projects
  }

  let(:team) {
    team = create :team, creator: @user, path: 'gitlabhq'
    team.add_users([@another_user.id], Gitlab::Access::DEVELOPER)

    clear_prepare_data

    team
  }

  let(:project_with_code) {
    pr = create :project, creator: @another_user
    clear_prepare_data
    pr
  }

  let(:create_events_summaries) {
    events_summaries = []
    EVENTS_SUMMARY_PERIODS.each do |period, details|
      events_summary = Event::Summary.new({
        title: "#{period.to_s.capitalize} digest title",
        period: period
      })
      events_summary.last_send_date = Time.zone.now
      events_summary.user = @user
      events_summary.save

      subscriptions = @user.personal_subscriptions
      subscriptions.each do |subscription|
        events_summary.summary_entity_relationships.create(entity_id:   subscription.target_id,
                                                           entity_type: subscription.target_type)
      end

      events_summaries << events_summary
    end

    events_summaries
  }

  describe "Users emails" do
    before do
      Gitlab::Event::Subscription.create_auto_subscription(@user, :user)

      @watched_users = []
      ITERATION_COUNT.times do
        @watched_users << create(:user)
      end
    end

    context "target User" do
      it "should block a few users" do
        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            watched_user.block
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should activate a few users" do
        @watched_users.each do |watched_user|
          watched_user.block
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            watched_user.activate
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should update a few users" do
        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            watched_user.update_attributes({
              name: "#{watched_user.name}_updated"
            })
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end

    context "target UsersGroup" do
      before do
        @group = create :group, owner: @user

        clear_prepare_data
      end

      it "should join a few user to group" do
        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            params = {
              user_ids: [ watched_user.id ],
              group_access: Gitlab::Access::DEVELOPER
            }
            GroupsService.new(@another_user, @group, params).add_membership
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should update a few user relationship for group" do
        @watched_users.each do |watched_user|
          params = {
            user_ids: [ watched_user.id ],
            group_access: Gitlab::Access::DEVELOPER
          }
          GroupsService.new(@another_user, @group, params).add_membership
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            params = {
              group_access: Gitlab::Access::MASTER
            }
            GroupsService.new(@another_user, @group, params).update_membership(watched_user)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should left a few user from a group" do
        @watched_users.each do |watched_user|
          params = {
            user_ids: [ watched_user.id ],
            group_access: Gitlab::Access::DEVELOPER
          }
          GroupsService.new(@another_user, @group, params).add_membership
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            GroupsService.new(@another_user, @group).remove_membership(watched_user)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end

    context "target UsersProject" do
      before do
        @group = create :group, owner: @user
        @project = create :empty_project, creator: @user, namespace: @group
        @project.team << [@another_user, Gitlab::Access::MASTER]

        clear_prepare_data
      end

      it "should join a few user to project" do
        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            params = {
              user_ids: [ watched_user.id ],
              project_access: Gitlab::Access::DEVELOPER
            }
            ProjectsService.new(@user, @project, params).add_membership
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should update a few users project relationships" do
        @watched_users.each do |watched_user|
          params = {
            user_ids: [ watched_user.id ],
            project_access: Gitlab::Access::DEVELOPER
          }
          ProjectsService.new(@user, @project, params).add_membership
        end
        clear_prepare_data

        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            params = {
              team_member: {
                project_access: Gitlab::Access::MASTER
              }
            }
            ProjectsService.new(@user, @project, params).update_membership(watched_user)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should delete a few users from project" do
        @watched_users.each do |watched_user|
          params = {
            user_ids: [ watched_user.id ],
            project_access: Gitlab::Access::DEVELOPER
          }
          ProjectsService.new(@user, @project, params).add_membership
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            ProjectsService.new(@user, @project).remove_membership(watched_user)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end

    context "target TeamUserRelationship" do
      before do
        @team = team
        clear_prepare_data
      end

      it "should add a few users to team" do
        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            params = {
              user_ids: [watched_user.id],
              team_access: Gitlab::Access::DEVELOPER
            }
            TeamsService.new(@another_user, @team, params).add_memberships
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should update a team user relationship of a few users" do
        @watched_users.each do |watched_user|
          params = {
            user_ids: [watched_user.id],
            team_access: Gitlab::Access::DEVELOPER
          }
          TeamsService.new(@another_user, @team, params).add_memberships
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            params = {
              team_access: Gitlab::Access::MASTER
            }
            TeamsService.new(@another_user, @team, params).update_memberships(watched_user)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should remove a few users from team" do
        @watched_users.each do |watched_user|
          params = {
            user_ids: [watched_user.id],
            team_access: Gitlab::Access::DEVELOPER
          }
          TeamsService.new(@another_user, @team, params).add_memberships
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          @watched_users.each do |watched_user|
            TeamsService.new(@another_user, @team).delete_membership(watched_user)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end

  end

  describe "Projects emails" do
    before do
      Gitlab::Event::Subscription.create_auto_subscription(@user, :project)

      @projects = projects
    end

    it "should update a few projects and send one summary email " do

      create_events_summaries

      collect_events do
        @projects.each do |project|
          params = { project: attributes_for(:empty_project) }
          ProjectsService.new(@another_user, project, params).update
        end
      end

      add_retry

      select_digest_mails(mails).count.should == expected_mails_count

      clear_prepare_data

      add_retry

      mails.should be_blank
    end

    it "should update a few projects with push and send one summary email with push" do

      @project = project_with_code
      @oldrev = '93efff945215a4407afcaf0cba15ac601b56df0d'
      @newrev = 'b19a04f53caeebf4fe5ec2327cb83e9253dc91bb'
      @ref = 'refs/heads/master'

      clear_prepare_data

      create_events_summaries

      collect_events do
        Event::Summary.find_each {|s| s.summary_entity_relationships.each {|r| r.options = [:push]; r.save }}

        @projects.each do |project|
          params = { project: attributes_for(:empty_project) }
          ProjectsService.new(@another_user, project, params).update
        end

        GitPushService.new(@another_user, @project, @oldrev, @newrev, @ref).execute
      end

      add_retry

      select_digest_mails(mails).count.should == expected_mails_count

      clear_prepare_data

      add_retry

      mails.should be_blank
    end

    context "issues" do

      it "should create a few issues in project and send one summary email" do
        project = @projects.first

        create_events_summaries

        collect_events do
          ITERATION_COUNT.times do
            create :issue, project: project
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should change status of issue a few times in project and send one summary email" do
        project = @projects.first

        issues = []
        ITERATION_COUNT.times do
          issues << create(:issue, project: project)
        end
        available_statuses = [:close, :reopen]

        clear_prepare_data

        create_events_summaries

        collect_events do
          issues.each do |issue|
            available_statuses.each do |state|
              issue.state_event = state
              issue.save
            end
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should delete a few issues in project and send one summary email" do
        project = @projects.first

        issues = []
        ITERATION_COUNT.times do
          issues << create(:issue, project: project)
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          issues.each do |issue|
            issue.destroy
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end

    context "#milestone" do

      it "should create a few milestones and send one summary emails" do
        create_events_summaries

        collect_events do
          @projects.each do |project|
            create :milestone, project: project
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should change status of a few milestones and send one summary email" do
        milestones = []
        ITERATION_COUNT.times do
          @projects.each do |project|
            milestones << create(:milestone, project: project)
          end
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          milestones.each do |milestone|
            milestone.close
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end

    context "#note" do
      it "should create a few notes for project and send one summary email and one email for commit author" do
        project = ProjectsService.new(@another_user, attributes_for(:project)).create
        project.team << [@user, Gitlab::Access::DEVELOPER]

        clear_prepare_data

        create_events_summaries

        collect_events do
          ITERATION_COUNT.times do
            ProjectsService.new(@another_user, project, note: attributes_for(:note_on_commit)).notes.create
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should add a few note for merge request and send one summary emails" do
        project = project_with_code

        merge_request = ProjectsService.new(@another_user,
                                            project,
                                            attributes_for(:merge_request_with_diffs,
                                                           source_project: project,
                                                           target_project: project)
                                           ).merge_request.create

        params = { note: attributes_for(:note_on_merge_request, noteable: merge_request) }

        clear_prepare_data

        create_events_summaries

        collect_events do
          ITERATION_COUNT.times do
            params = { note: attributes_for(:note_on_merge_request, noteable: merge_request) }
            ProjectsService.new(@another_user, project, params).notes.create

            params = { note: attributes_for(:note_on_merge_request_diff, noteable: merge_request) }
            ProjectsService.new(@another_user, project, params).notes.create
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should add a few note for issue and send one summary emails" do
        project = @projects.first
        issue = create :issue, project: project
        params = { note: attributes_for(:note_on_issue, noteable: issue) }

        clear_prepare_data

        create_events_summaries

        collect_events do
          ITERATION_COUNT.times do
            ProjectsService.new(@another_user, project, params).notes.create
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end # note

    context "#merge_request" do
      before do
        Gitlab::Event::Subscription.create_auto_subscription(@user, :project)
      end

      it "should create a few merge requests and send one summary email" do
        project = project_with_code

        create_events_summaries

        collect_events do
          ITERATION_COUNT.times do
            ProjectsService.new(@another_user, project, attributes_for(:merge_request, source_project: project, target_project: project)).merge_request.create
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should change statuses of a few merge requests and send one summary email" do
        project = project_with_code

        merge_requests = []
        ITERATION_COUNT.times do
          merge_requests << ProjectsService.new(@another_user, project, attributes_for(:merge_request, source_project: project, target_project: project)).merge_request.create
        end

        state_events = [ :close, :reopen, :merge ]

        create_events_summaries

        ActionMailer::Base.deliveries.clear

        collect_events do
          state_events.each do |state_event|
            merge_requests.each do |merge_request|
              EventHierarchyWorker.reset
              RequestStore.store[:borders] = []

              params = {
                merge_request: {
                  state_event: state_event
                }
              }
              ProjectsService.new(@user, project, params).merge_request(merge_request).update
            end
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end # merge_request

    context "#snippet" do

      it "should create a few snippets and send one summary emails" do
        pending "add (or delete) tests for snippets digests"

        project = @projects.first

        clear_prepare_data

        create_events_summaries

        collect_events do
          ITERATION_COUNT.times do
            create :project_snippet, project: project, author: @another_user
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should update a few snippets and send one summary emails" do
        pending "add (or delete) tests for snippets digests"

        project = @projects.first

        project_snippets = []
        ITERATION_COUNT.times do
          project_snippets << create(:project_snippet, project: project, author: @another_user)
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          project_snippets.each do |snippet|
            params = attributes_for :project_snippet, project: nil, author: nil
            snippet.update_attributes(params)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should delete a few snippets and send one summary emails" do
        pending "add (or delete) tests for snipets digests"

        project = @projects.first

        project_snippets = []
        ITERATION_COUNT.times do
          project_snippets << create(:project_snippet, project: project, author: @another_user)
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          project_snippets.each do |snippet|
            snippet.destroy
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

    end # snippet

    context "project hook" do

      it "should create a few project hooks and send one summary emails" do
        project = @projects.first

        clear_prepare_data

        create_events_summaries

        collect_events do
          ITERATION_COUNT.times do
            create :project_hook, project: project
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should update a few project hooks and send one summary emails" do
        project = @projects.first

        project_hooks= []
        ITERATION_COUNT.times do
          project_hooks << create(:project_hook, project: project)
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          project_hooks.each do |project_hook|
            params = attributes_for :project_hook
            project_hook.update_attributes(params)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should delete a few project hooks and send one summary emails" do
        project = @projects.first

        project_hooks = []
        ITERATION_COUNT.times do
          project_hooks << create(:project_hook, project: project)
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          project_hooks.each do |project_hook|
            project_hook.destroy
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

    end # project hook

    context "#protected branch" do
      it "should create a few protected branches and send one summary email" do
        create_events_summaries

        collect_events do
          @projects.each do |project|
            create :protected_branch, project: project, name: "master"
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should delete a few protected branches and send one summary email" do
        protected_branches = []
        @projects.each do |project|
          protected_branches << create(:protected_branch, project: project, name: "master")
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          protected_branches.each do |protected_branch|
            protected_branch.destroy
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end

    context "#services" do
      it "should create a few services and send one summary email" do
        pending "add (or delete) tests for services digests"

        project = @projects.first

        create_events_summaries

        collect_events do
          Service.implement_services.map {|s| s.new }.each do |service|
            @service = create :"#{service.to_param}_service", project: project
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should update a few services and send one summary email" do
        pending "add (or delete) tests for services digests"

        project = @projects.first
        services = []
        Service.implement_services.map {|s| s.new }.each do |service|
          services << create(:"#{service.to_param}_service", project: project)
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          services.each do |service|
            service.enable
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should destroy a few services and send one summary email" do
        pending "add (or delete) tests for services digests"

        project = @projects.first
        services = []
        Service.implement_services.map {|s| s.new }.each do |service|
          services << create(:"#{service.to_param}_service", project: project)
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          services.each do |service|
            service.destroy
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end

    context "#team_project_relationship" do
      before do
        @team = team
      end

      it "should assign a team to a few projects and send one summary email" do
        create_events_summaries

        collect_events do
          @projects.each do |project|
            params = {
              team_ids: [ @team.id ]
            }
            ProjectsService.new(@another_user, project, params).assign_team
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should resign a team to a few projects and send one summary email" do

        @projects.each do |project|
          params = {
            team_ids: [ @team.id ]
          }
          ProjectsService.new(@another_user, project, params).assign_team
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          @projects.each do |project|
            ProjectsService.new(@another_user, project).resign_team(@team)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end

    context "#users_project" do
      it "should join a user to a few projects and send one summary email" do
        user = create :user

        clear_prepare_data

        create_events_summaries

        collect_events do
          @projects.each do |project|
            params = {
              user_ids: [ user.id ],
              project_access: Gitlab::Access::DEVELOPER
            }
            ProjectsService.new(@user, project, params).add_membership
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should update a user project relation for a few projects and send one summary email" do
        create_events_summaries

        collect_events do
          @projects.each do |project|
            params = {
              team_member: {
                project_access: Gitlab::Access::MASTER
              }
            }
            ProjectsService.new(@user, project, params).update_membership(@another_user)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should left a user from a few projects and send one summary email" do
        create_events_summaries

        collect_events do
          @projects.each do |project|
            ProjectsService.new(@user, project).remove_membership(@another_user)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end
  end

  describe "Push actions emails" do
    before do
      Gitlab::Event::Subscription.create_auto_subscription(@user, :project)
      #SubscriptionService.subscribe(@user, :all, :project, :all)

      @oldrev = '93efff945215a4407afcaf0cba15ac601b56df0d'
      @newrev = 'b19a04f53caeebf4fe5ec2327cb83e9253dc91bb'
      @ref = 'refs/heads/master'

      # @project = projects.first
      @project = project_with_code
      @project.team << [@another_user, Gitlab::Access::DEVELOPER]
      #@project.default_branch = 'master'
      @project.save

      clear_prepare_data
    end

    it "should push" do

      create_events_summaries

      collect_events do
        GitPushService.new(@another_user, @project, @oldrev, @newrev, @ref).execute
      end

      add_retry

    end

    it "should push new branch" do
      @oldrev = '0000000000000000000000000000000000000000'
      create_events_summaries

      collect_events do
        GitPushService.new(@another_user, @project, @oldrev, @newrev, @ref).execute
      end

      add_retry

    end

    it "should delete branch" do
      @newrev = '0000000000000000000000000000000000000000'
      create_events_summaries

      collect_events do
        GitPushService.new(@another_user, @project, @oldrev, @newrev, @ref).execute
      end

      add_retry

    end

    it "should push new tag" do
      @oldrev = '0000000000000000000000000000000000000000'
      @ref = 'refs/tags/v2.2.0'
      create_events_summaries

      collect_events do
        GitPushService.new(@another_user, @project, @oldrev, @newrev, @ref).execute
      end

      add_retry

    end

    it "should delete tag" do
      @newrev = '0000000000000000000000000000000000000000'
      @ref = 'refs/tags/v2.2.0'
      create_events_summaries

      collect_events do
        GitPushService.new(@another_user, @project, @oldrev, @newrev, @ref).execute
      end

      add_retry

    end
  end

  describe "Groups emails" do
    before do
      Gitlab::Event::Subscription.create_auto_subscription(@user, :group)

      @groups = groups
    end

    it "update a few groups and should send one summary email" do
      create_events_summaries

      collect_events do
        @groups.each do |group|
          group.name = "#{group.name}_update"
          group.save
        end
      end

      add_retry

      select_digest_mails(mails).count.should == expected_mails_count
    end

    context "#project" do
      it "should create a few projects in few groups and send one summary email" do
        create_events_summaries

        collect_events do
          @groups.each do |group|
            params = attributes_for(:project, namespace_id: group.id)
            ProjectsService.new(@user, params).create
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should delete a few projects and send one summary email" do
        projects

        clear_prepare_data

        create_events_summaries

        collect_events do
          projects.each do |project|
            ProjectsService.new(@another_user, project).delete
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end

    context "#team_group_relationship" do
      before do
        @team = team
      end

      it "should assign a team to a few groups and send one summary email" do
        create_events_summaries

        collect_events do
          @groups.each do |group|
            params = {
              team_ids: [ @team.id ]
            }
            GroupsService.new(@another_user, group, params).assign_team
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should resign a team from a few groups and send one summary email" do

        @groups.each do |group|
          params = {
            team_ids: [ @team.id ]
          }
          GroupsService.new(@another_user, group, params).assign_team
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          @groups.each do |group|
            GroupsService.new(@another_user, group).resign_team(@team)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

    end

    context "#users_group" do
      it "should join a user to a few groups and send one summary email" do
        user = create :user

        clear_prepare_data

        create_events_summaries

        collect_events do
          @groups.each do |group|
            params = {
              user_ids: [ user.id ],
              group_access: Gitlab::Access::DEVELOPER
            }
            GroupsService.new(@another_user, group, params).add_membership
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should update a user group relation for a few groups and send one summary email" do
        @groups.each do |group|
          params = {
            user_ids: [ @another_user.id ],
            group_access: Gitlab::Access::DEVELOPER
          }
          GroupsService.new(@another_user, group, params).add_membership
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          @groups.each do |group|
            params = {
              group_access: Gitlab::Access::MASTER
            }
            GroupsService.new(@another_user, group, params).update_membership(@another_user)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end

      it "should left a user from a few groups and send one summary email" do
        @groups.each do |group|
          params = {
            user_ids: [ @another_user.id ],
            group_access: Gitlab::Access::DEVELOPER
          }
          GroupsService.new(@another_user, group, params).add_membership
        end

        clear_prepare_data

        create_events_summaries

        collect_events do
          @groups.each do |group|
            GroupsService.new(@another_user, group).remove_membership(@another_user)
          end
        end

        add_retry

        select_digest_mails(mails).count.should == expected_mails_count
      end
    end
  end

  describe "Teams emails" do
    before do
      Gitlab::Event::Subscription.create_auto_subscription(@user, :team)

      @team = team
      @groups = groups
      @projects = projects
    end

    it "should change info about team a few times and send one summary email" do
      create_events_summaries

      collect_events do
        ITERATION_COUNT.times do
          @team.description = generate :description
          @team.save
        end
      end

      add_retry

      select_digest_mails(mails).count.should == expected_mails_count
    end

    it "should add developers a few times and send one summary email" do
      developers = []
      ITERATION_COUNT.times do
        developers << create(:user)
      end
      clear_prepare_data

      create_events_summaries

      collect_events do
        developers.each do |developer|
          @team.add_users([developer.id], Gitlab::Access::DEVELOPER)
        end
      end

      add_retry

      select_digest_mails(mails).count.should == expected_mails_count
    end

    it "should remove developeres a few times and send one summary email" do
      developers = []
      ITERATION_COUNT.times do
        user = create(:user)
        developers << user
        @team.add_users([user.id], Gitlab::Access::DEVELOPER)
      end

      clear_prepare_data

      create_events_summaries

      collect_events do
        developers.each do |developer|
          @team.remove_user(developer)
        end
      end

      add_retry

      select_digest_mails(mails).count.should == expected_mails_count
    end

    it "should change access for user a few times and send one summary email" do
      accesses = [
        Gitlab::Access::MASTER,
        Gitlab::Access::DEVELOPER,
        Gitlab::Access::GUEST,
        Gitlab::Access::MASTER,
      ]

      create_events_summaries

      collect_events do
        accesses.each do |access|
          params = {
            team_access: access
          }
          TeamsService.new(@user, @team, params).update_memberships(@another_user)
          EventHierarchyWorker.reset
        end
      end

      add_retry

      select_digest_mails(mails).count.should == expected_mails_count
    end

    it "should designate team to group a few times and send one summary email" do
      create_events_summaries

      collect_events do
        @groups.each do |group|
          params = { group_ids: [group.id] }
          TeamsService.new(@user, @team, params).assign_on_groups
        end
      end

      add_retry

      select_digest_mails(mails).count.should == expected_mails_count
    end

    it "should designate team to project a few times and send one summary email" do
      create_events_summaries

      collect_events do
        @projects.each do |project|
          params = { project_ids: [project.id] }
          TeamsService.new(@another_user, @team, params).assign_on_projects
        end
      end

      add_retry

      select_digest_mails(mails).count.should == expected_mails_count
    end

    it "should remove team from group a few times and send one summary email" do
      @groups.each do |group|
        params = { group_ids: [group.id] }
        TeamsService.new(@user, @team, params).assign_on_groups
      end
      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      create_events_summaries

      collect_events do
        @groups.each do |group|
          TeamsService.new(@another_user, @team).resign_from_groups(group)
        end
      end

      add_retry

      select_digest_mails(mails).count.should == expected_mails_count
    end

    it "should remove team from project a few times and send one summary email" do
      Event.destroy_all

      @projects.each do |project|
        params = { project_ids: [project.id] }
        TeamsService.new(@another_user, @team, params).assign_on_projects
      end
      ActionMailer::Base.deliveries.clear; EventHierarchyWorker.reset

      create_events_summaries

      collect_events do
        @projects.each do |project|
          TeamsService.new(@another_user, @team).resign_from_projects(project)
        end
      end

      add_retry

      select_digest_mails(mails).count.should == expected_mails_count
    end
  end

  describe "Global digest" do
    before do
      @group = create :group, owner: @another_user
      @team =  create :team, creator: @another_user

      @user.admin = true
      @user.save

      @another_user.admin = true
      @another_user.save

      Gitlab::Event::Subscription.create_auto_subscription(@user, :user)
      Gitlab::Event::Subscription.create_auto_subscription(@user, :project)
      Gitlab::Event::Subscription.create_auto_subscription(@user, :group)
      Gitlab::Event::Subscription.create_auto_subscription(@user, :team)

      @watched_users = []
      ITERATION_COUNT.times do
        @watched_users << create(:user)
      end

      @watched_group     = GroupsService.new(@another_user, attributes_for(:group)).create

      @watched_team      = create :team,    creator: @another_user
      @watched_team.add_users([@another_user.id], Gitlab::Access::MASTER)

      @project_with_code = create :project, creator: @another_user, namespace: @group
      @project_with_code.team << [@another_user, Gitlab::Access::MASTER]

      @project = create :empty_project,     creator: @another_user, namespace: @group
      @project.team << [@another_user, Gitlab::Access::MASTER]

      clear_prepare_data

      create_events_summaries
    end

    it "should send didgest with multiple actions and multiple sources" do

      collect_events do
        # UsersProject action
        # join
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          params = {
            user_ids: [ watched_user.id ],
            project_access: Gitlab::Access::DEVELOPER
          }
          ProjectsService.new(@another_user, @project, params).add_membership
        end

        # update
        @watched_users.each do |watched_user|
          params = {
            team_member: {
              project_access: Gitlab::Access::MASTER
            }
          }
          ProjectsService.new(@another_user, @project, params).update_membership(watched_user)
        end

        # left
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          ProjectsService.new(@another_user, @project).remove_membership(watched_user)
        end

        # UsersGroup actions
        # join
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          params = {
            user_ids: [ watched_user.id ],
            group_access: Gitlab::Access::DEVELOPER
          }
          GroupsService.new(@another_user, @group, params).add_membership
        end

        # update
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          params = {
            group_access: Gitlab::Access::MASTER
          }
          GroupsService.new(@another_user, @group, params).update_membership(watched_user)
        end

        # left
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          GroupsService.new(@another_user, @group).remove_membership(watched_user)
        end

        # TeamUserRelationship actions
        # join
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          params = {
            user_ids: [watched_user.id],
            team_access: Gitlab::Access::DEVELOPER
          }
          TeamsService.new(@another_user, @team, params).add_memberships
        end

        # update
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          params = {
            team_access: Gitlab::Access::MASTER
          }
          TeamsService.new(@another_user, @team, params).update_memberships(watched_user)
        end

        # left
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          TeamsService.new(@another_user, @team).delete_membership(watched_user)
        end

        # update
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          watched_user.update_attributes(name: watched_user.name + "_updated")
        end


        # Project
        # Issue actions
        # #opened
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        issues = []
        ITERATION_COUNT.times do
          issues << create(:issue, author: @another_user, project: @project_with_code)
        end

        # #closed
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        issues.each do |issue|
          issue.close
        end

        # #reopened
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        issues.each do |issue|
          issue.reopen
        end

        # MergeRequest actions
        # #opened
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        merge_requests = []
        ITERATION_COUNT.times do
          merge_requests << ProjectsService.new(@another_user, @project_with_code, attributes_for(:merge_request, source_project: @project_with_code, target_project: @project_with_code)).merge_request.create
        end

        # #assigned
        # TODO
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # #reassigned
        # TODO
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # #closed #reopened #merged
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        state_events = [ :close, :reopen, :merge ]
        ActionMailer::Base.deliveries.clear

        state_events.each do |state_event|
          merge_requests.each do |merge_request|
            EventHierarchyWorker.reset
            RequestStore.store[:borders] = []

            params = {
              merge_request: {
                state_event: state_event
              }
            }
            ProjectsService.new(@another_user, @project_with_code, params).merge_request(merge_request).update
          end
        end

        # Milestone actions
        # #created
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        milestone = create :milestone, project: @project_with_code

        # #closed
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        milestone.close

        # Note actions
        #
        # #commented_commit
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        ITERATION_COUNT.times do
          ProjectsService.new(@another_user, @project_with_code, note: attributes_for(:note_on_commit)).notes.create
        end

        # #commented issue
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        issue = create :issue, project: @project_with_code
        params = { note: attributes_for(:note_on_issue, noteable: issue) }

        ITERATION_COUNT.times do
          ProjectsService.new(@another_user, @project_with_code, params).notes.create
        end

        # #commented marge request
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        ITERATION_COUNT.times do
          params = { note: attributes_for(:note_on_merge_request, noteable: merge_requests.first) }
          ProjectsService.new(@another_user, @project_with_code, params).notes.create

          params = { note: attributes_for(:note_on_merge_request_diff, noteable: merge_requests.first) }
          ProjectsService.new(@another_user, @project_with_code, params).notes.create
        end

        # Project Hook actions
        # #added
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        project_hooks= []
        ITERATION_COUNT.times do
          project_hooks << create(:project_hook, project: @project_with_code)
        end

        # #updated
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        project_hooks.each do |project_hook|
          params = attributes_for :project_hook
          project_hook.update_attributes(params)
        end

        # #deleted
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        project_hooks.each do |project_hook|
          project_hook.destroy
        end

        # Protected Branch actions
        # #protected
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        protected_branch = create(:protected_branch, project: @project_with_code, name: "master")

        # #unprotected
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        protected_branch.destroy

        # Push Actions
        # #pushed
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @oldrev = '93efff945215a4407afcaf0cba15ac601b56df0d'
        @newrev = 'b19a04f53caeebf4fe5ec2327cb83e9253dc91bb'
        @ref = 'refs/heads/master'
        GitPushService.new(@another_user, @project_with_code, @oldrev, @newrev, @ref).execute

        # #created_branch
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @oldrev = '0000000000000000000000000000000000000000'
        GitPushService.new(@another_user, @project_with_code, @oldrev, @newrev, @ref).execute

        # #deleted_branch
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @oldrev = '93efff945215a4407afcaf0cba15ac601b56df0d'
        @newrev = '0000000000000000000000000000000000000000'
        GitPushService.new(@another_user, @project_with_code, @oldrev, @newrev, @ref).execute

        # #created_tag
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @oldrev = '0000000000000000000000000000000000000000'
        @ref = 'refs/tags/v2.2.0'
        GitPushService.new(@another_user, @project_with_code, @oldrev, @newrev, @ref).execute

        # #deleted_tag
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @oldrev = '93efff945215a4407afcaf0cba15ac601b56df0d'
        @newrev = '0000000000000000000000000000000000000000'
        @ref = 'refs/tags/v2.2.0'

        # TeamProjectRelationship actions
        # #assigned
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        params = { team_ids: [ @team.id ] }
        ProjectsService.new(@another_user, @project_with_code, params).assign_team

        # #resigned
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        ProjectsService.new(@another_user, @project_with_code, params).resign_team(@team)

        # UsersProject actions
        # #joined
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        params = {
          user_ids: [ @user.id ],
          project_access: Gitlab::Access::DEVELOPER
        }
        ProjectsService.new(@another_user, @project_with_code, params).add_membership

        # #updated
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        params = { team_member: { project_access: Gitlab::Access::MASTER } }
        ProjectsService.new(@another_user, @project_with_code, params).update_membership(@user)

        # #left
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        ProjectsService.new(@another_user, @project_with_code).remove_membership(@user)

        # WebHook actions
        # TODO
        # #added
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # #updated
        # TODO
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # #deleted
        # TODO
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # Project actions
        # #imported
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        users_ids = @watched_users.map(&:id)
        params = { project: attributes_for(:empty_project, creator_id: @another_user.id, namespace_id: @group.id) }
        @first_project = ProjectsService.new(@another_user, params[:project]).create

        params = { user_ids: users_ids, project_access: Gitlab::Access::DEVELOPER }
        ProjectsService.new(@another_user, @first_project, params).add_membership

        params = { source_project_id: @first_project.id }
        ProjectsService.new(@another_user, @project_with_code, params).import_memberships

        # #members_removed
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        ProjectsService.new(@another_user, @project_with_code, { ids: users_ids }).batch_remove_memberships

        # #members_added
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        params = { user_ids: users_ids, project_access: Gitlab::Access::DEVELOPER }
        ProjectsService.new(@another_user, @project_with_code, params).add_membership

        # #members_updated
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        ProjectsService.new(@another_user, @project_with_code, { ids: users_ids, team_member: { project_access: Gitlab::Access::MASTER } }).batch_update_memberships

        # #teams_added
        # TODO
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # #transfer
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        params = attributes_for :group, owner: @another_user.id
        @another_group = GroupsService.new(@another_user, params).create
        params = { project: { namespace_id: @another_group.id }}
        ProjectsService.new(@another_user, @project_with_code, params).transfer

        # #updated
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @project_with_code.update_attributes(name: @project_with_code.name + "_after_update")

        # #deleted
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        ProjectsService.new(@another_user, @project_with_code).delete

        # Group
        # Project actions
        # #added
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        params = attributes_for(:project, namespace_id: @watched_group.id)
        project_in_group = ProjectsService.new(@another_user, params).create

        # #removed
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        params = { project: { namespace_id: @another_group.id }}
        ProjectsService.new(@another_user, project_in_group, params).transfer

        params = { project: { namespace_id: @watched_group.id }}
        ProjectsService.new(@another_user, project_in_group, params).transfer

        # #updated
        # TODO
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # #deleted
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        ProjectsService.new(@another_user, project_in_group).delete

        # Team actions
        # #assigned
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        params = { team_ids: [ @team.id ] }
        GroupsService.new(@another_user, @watched_group, params).assign_team

        # #resigned
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        params = { team_ids: [ @team.id ] }
        GroupsService.new(@another_user, @watched_group).resign_team(@team)

        # User actions
        # #joined
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |wu|
          params = {
            user_ids: [ wu.id ],
            group_access: Gitlab::Access::DEVELOPER
          }
          GroupsService.new(@another_user, @watched_group, params).add_membership
        end

        # #updated
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |wu|
          params = { group_access: Gitlab::Access::MASTER }
          GroupsService.new(@another_user, @watched_group, params).update_membership(wu)
        end

        # #deleted
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |wu|
          params = {
            user_ids: [ wu.id ],
            group_access: Gitlab::Access::DEVELOPER
          }
          GroupsService.new(@another_user, @watched_group).remove_membership(wu)
        end

        # #members_added
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        params = { user_ids: users_ids, group_access: Gitlab::Access::DEVELOPER }
        GroupsService.new(@another_user, @watched_group, params).add_membership

        # #teams_added
        # TODO
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # Group actions
        # #updated
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_group.update_attributes(attributes_for(:group))

        # #deleted
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        GroupsService.new(@another_user, @watched_group).delete

        # Team
        # Project actions
        # #assigned
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # #resigned
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # Group actions
        # #assigned
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # resigned
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # User actions
        # #joined
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          params = {
            user_ids: [watched_user.id],
            team_access: Gitlab::Access::DEVELOPER
          }
          TeamsService.new(@another_user, @watched_team, params).add_memberships
        end


        # #updated
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          params = {
            team_access: Gitlab::Access::MASTER
          }
          TeamsService.new(@another_user, @watched_team, params).update_memberships(watched_user)
        end

        # #left
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          TeamsService.new(@another_user, @watched_team).delete_membership(watched_user)
        end

        # Team actions
        # #updated
        # TODO
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # #groups_added
        # TODO
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # #projects_added
        # TODO
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # #members_added
        # TODO
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []

        # #deleted
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        TeamsService.new(@another_user, @watched_team).delete

        # block
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          watched_user.block
        end

        # User action
        # activate
        EventHierarchyWorker.reset
        RequestStore.store[:borders] = []
        @watched_users.each do |watched_user|
          watched_user.activate
        end
      end

      # # delete
      #EventHierarchyWorker.reset
      #RequestStore.store[:borders] = []
      #@watched_users.each do |watched_user|
      #watched_user.destroy
      #end

      mails.clear

      add_retry

      save_emails

      select_digest_mails(mails).count.should == EVENTS_SUMMARY_PERIODS.count
    end
  end
end
