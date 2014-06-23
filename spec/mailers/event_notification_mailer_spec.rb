require "spec_helper"

describe EventNotificationMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  def clear_prepare_data
    Event.delete_all
    Event::Subscription::Notification.delete_all
    ActionMailer::Base.deliveries.clear
    EventHierarchyWorker.reset
    RequestStore.store[:borders] = []
  end

  def collect_mails_data
    clear_prepare_data
    Gitlab::Event::Factory.unstub(:call)
    yield
    Gitlab::Event::Factory.stub(call: true)
    @mails = ActionMailer::Base.deliveries
    @mails_count = @mails.count
    @email = @mails.first
  end

  def clean_destroy
    EventSubscriptionDestroyWorker.any_instance.stub(:perform).and_return(true)
    yield
  end

  let(:group)   { g  = create :group,   owner:   @another_user;                   clear_prepare_data; g }
  let(:project) { pr = create :project, creator: @another_user, namespace: group; clear_prepare_data; pr }

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

  after do
    #clean_destroy do
      #@commiter_user.destroy
      #@another_user.destroy
      #@user.destroy
    #end
  end

  describe "Project mails" do
    before { Gitlab::Event::Subscription.create_auto_subscription(@user, :project) }

    context "when event source - project " do
      context "when create project" do
        before do
          collect_mails_data do
            @project = ProjectsService.new(@another_user, attributes_for(:project)).create
          end
        end

        it "only one message" do
          @mails_count.should == 1
        end

        it "correct email" do
          @email.from.first.should == @another_user.email
          @email.to.should be_nil
          @email.cc.should be_nil
          @email.bcc.count.should == 1
          @email.bcc.first.should == @user.email
          @email.subject.should =~ /created/
          @email.in_reply_to.should == "project-#{@project.path_with_namespace}"
          @email.body.should_not be_empty
        end
      end

      context "when project is present" do
        context "when update project" do
          before do
            @project_for_update = ProjectsService.new(@another_user, attributes_for(:project)).create

            collect_mails_data do
              ProjectsService.new(@another_user, @project_for_update, { project: attributes_for(:project) }).update
            end

            @old_path_with_namespace = @project_for_update.path_with_namespace
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.subject.should =~ /updated/
            @email.in_reply_to.should == "project-#{@old_path_with_namespace}"
            @email.body.should_not be_empty
          end
        end

        context "when transfer project from user to group" do
          before do
            @project_for_transfer = ProjectsService.new(@another_user, attributes_for(:project)).create
            @old_path_with_namespace = @project_for_transfer.path_with_namespace
            @group = create :group, owner: @another_user
            params = { project: { namespace_id: @group.id }}

            collect_mails_data do
              ProjectsService.new(@another_user, @project_for_transfer, params).transfer
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{@old_path_with_namespace}"
            @email.body.should_not be_empty
          end
        end

        context "when transfer project from group to group" do
          before do
            @old_group = create :group, owner: @another_user
            @new_group = create :group, owner: @another_user

            params = { project: attributes_for(:project, creator_id: @another_user.id, namespace_id: @old_group.id) }
            @project_in_group = ProjectsService.new(@another_user, params[:project]).create
            @old_path_with_namespace = @project_in_group.path_with_namespace
            params = { project: { namespace_id: @new_group.id }}

            collect_mails_data do
              ProjectsService.new(@another_user, @project_in_group, params).transfer
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{@old_path_with_namespace}"
            @email.body.should_not be_empty
          end
        end

        context "when transfer project from group to user" do
          before do
            @old_group = create :group, owner: @another_user

            params = { project: attributes_for(:project, creator_id: @another_user.id, namespace_id: @old_group.id) }
            @project_in_group = ProjectsService.new(@another_user, params[:project]).create
            @old_path_with_namespace = @project_in_group.path_with_namespace
            params = { project: { namespace_id: @another_user.namespace.id }}

            collect_mails_data do
              ProjectsService.new(@another_user, @project_in_group, params).transfer
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{@old_path_with_namespace}"
            @email.body.should_not be_empty
          end
        end

        context "when destroy project" do
          before do
            @project_for_destroy = ProjectsService.new(@another_user, attributes_for(:project)).create
            @old_path_with_namespace = @project_for_destroy.path_with_namespace
            collect_mails_data do
              clean_destroy do
                ProjectsService.new(@another_user, @project_for_destroy).delete
              end
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{@old_path_with_namespace}"
            @email.body.should_not be_empty
          end
        end
      end
    end

    context "on exist project" do
      before { Gitlab::Event::Subscription.subscribe(@user, project) if Event::Subscription.by_target(project).empty? }

      context "when event source - issue" do
        context "when create issue" do
          before do
            collect_mails_data do
              @issue = ProjectsService.new(@another_user, project, attributes_for(:issue)).issue.create
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-issue-#{@issue.iid}"
            @email.body.should_not be_empty
          end
        end

        context "when issue present in project" do
          before do
            @issue = create :issue, project: project
          end

          context "when close issue" do
            before do
              params = { state_event: :close }
              collect_mails_data do
                ProjectsService.new(@another_user, project, params).issue(@issue).update
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-issue-#{@issue.iid}"
              @email.body.should_not be_empty
            end
          end

          context "when reopen issue" do
            before do
              @issue.close

              params = { state_event: :reopen }
              collect_mails_data do
                ProjectsService.new(@another_user, project, params).issue(@issue).update
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-issue-#{@issue.iid}"
              @email.body.should_not be_empty
            end
          end
        end
      end

      context "when event source - milestone" do
        context "when create milestone" do
          before do
            collect_mails_data do
              @milestone = create :milestone, project: project
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-milestone-#{@milestone.id}"
            @email.body.should_not be_empty
          end
        end

        context "when close milestone" do
          before do
            @milestone = create :milestone, project: project
            collect_mails_data do
              @milestone.close
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-milestone-#{@milestone.id}"
            @email.body.should_not be_empty
          end
        end
      end

      context "when event source - note" do
        context "when update note" do
          before do
            @note = ProjectsService.new(@another_user, project, { note: attributes_for(:note) }).notes.create

            collect_mails_data do
              @note.update_attributes(note: "#{@note.note}_updated")
            end
          end

          it { @mails_count.should == 0 }
        end

        context "when create note on commit" do
          before do
            project.team << [@commiter_user, 40]

            collect_mails_data do
              @note = ProjectsService.new(@another_user, project, note: attributes_for(:note_on_commit)).notes.create
            end
          end

          it "only two message" do
            @mails_count.should == 2
          end

          it "correct email for subscriber" do
            @mails.first.from.first.should == @another_user.email
            @mails.first.to.should be_nil
            @mails.first.cc.should be_nil
            @mails.first.bcc.count.should == 1
            @mails.first.bcc.first.should == @user.email
            @mails.first.in_reply_to.should == "project-#{project.path_with_namespace}-commit-bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a"
          end

          it "correct email to commiter" do
            @mails.last.from.first.should == @another_user.email
            @mails.last.to.should be_nil
            @mails.last.cc.should be_nil
            @mails.last.bcc.count.should == 1
            @mails.last.bcc.first.should == @commiter_user.email
            @mails.last.in_reply_to.should == "project-#{project.path_with_namespace}-commit-bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a"
          end
        end

        context "when create note on commit diff" do
          before do
            project.team << [@commiter_user, 40]
            params = { note: attributes_for(:note_on_commit_diff) }

            collect_mails_data do
              ProjectsService.new(@another_user, project, params).notes.create
            end
          end

          it "only two message" do
            @mails_count.should == 2
          end

          it "correct email for subscriber" do
            @mails.first.from.first.should == @another_user.email
            @mails.first.to.should be_nil
            @mails.first.cc.should be_nil
            @mails.first.bcc.count.should == 1
            @mails.first.bcc.first.should == @user.email
            @mails.first.in_reply_to.should == "project-#{project.path_with_namespace}-commit-bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a"
          end

          it "correct email to commiter" do
            @mails.last.from.first.should == @another_user.email
            @mails.last.to.should be_nil
            @mails.last.cc.should be_nil
            @mails.last.bcc.count.should == 1
            @mails.last.bcc.first.should == @commiter_user.email
            @mails.first.in_reply_to.should == "project-#{project.path_with_namespace}-commit-bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a"
          end
        end

        context "in project MR" do
          before do
            @merge_request = ProjectsService.new(@another_user, project, attributes_for(:merge_request, source_project: project, target_project: project)).merge_request.create
          end

          context "when create note on MR wall" do
            before do
              params = { note: attributes_for(:note_on_merge_request, noteable: @merge_request) }
              collect_mails_data do
                ProjectsService.new(@another_user, project, params).notes.create
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-merge_request-#{@merge_request.iid}"
              @email.body.should_not be_empty
            end
          end

          context "when create note on MR diff" do
            before do
              params = { note: attributes_for(:note_on_merge_request_diff, noteable: @merge_request) }
              collect_mails_data do
                ProjectsService.new(@another_user, project, params).notes.create
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-merge_request-#{@merge_request.iid}"
              @email.body.should_not be_empty
            end
          end
        end

        context "in project issue" do
          it { pending "add (or delete) tests for notes in project issue" }
        end
      end

      context "when source - merge_request" do
        context "when create MR" do
          before do
            collect_mails_data do
              @merge_request = ProjectsService.new(@another_user, project, attributes_for(:merge_request, source_project: project, target_project: project)).merge_request.create
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-merge_request-#{@merge_request.iid}"
            @email.body.should_not be_empty
          end
        end

        context "when create assigned MR" do
          before do
            collect_mails_data do
              @merge_request = ProjectsService.new(@another_user, project, attributes_for(:merge_request, source_project: project, target_project: project, assignee: @user)).merge_request.create
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-merge_request-#{@merge_request.iid}"
            @email.body.should_not be_empty
          end
        end

        context "when MR is present in project" do
          before do
            @merge_request = ProjectsService.new(@another_user, project, attributes_for(:merge_request, source_project: project, target_project: project)).merge_request.create
          end

          context "when update MR" do
            before do
              collect_mails_data do
                @merge_request.update_attributes(title: "#{@merge_request.title}_updated")
              end
            end

            it { @mails_count.should == 0 }
          end

          context "when assignee MR" do
            before do
              params = {
                merge_request: {
                  assignee_id: @another_user.id
                }
              }

              collect_mails_data do
                ProjectsService.new(@user, project, params).merge_request(@merge_request).update
              end
            end

            it "only one message" do
              @mails_count.should == 2
            end

            it "correct email for subscriber" do
              @mails.last.from.first.should == @another_user.email
              @mails.first.to.should be_nil
              @mails.first.cc.should be_nil
              @mails.first.bcc.count.should == 1
              @mails.first.bcc.first.should == @user.email
              @mails.first.in_reply_to.should == "project-#{project.path_with_namespace}-merge_request-#{@merge_request.iid}"
              @mails.first.body.should_not be_empty
            end

            it "correct email for assignee" do
              @mails.last.from.first.should == @another_user.email
              @mails.last.to.should be_nil
              @mails.last.cc.should be_nil
              @mails.last.bcc.count.should == 1
              @mails.last.bcc.first.should == @another_user.email
              @mails.last.in_reply_to.should == "project-#{project.path_with_namespace}-merge_request-#{@merge_request.iid}"
              @mails.last.body.should_not be_empty
            end
          end

          context "when reassignee MR" do
            before do
              params = {
                merge_request: {
                  assignee_id: @another_user.id
                }
              }

              ProjectsService.new(@user, project, params).merge_request(@merge_request).update

              params = {
                merge_request: {
                  assignee_id: @user.id
                }
              }

              collect_mails_data do
                ProjectsService.new(@user, project, params).merge_request(@merge_request).update
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-merge_request-#{@merge_request.iid}"
              @email.body.should_not be_empty
            end
          end

          context "when merge MR" do
            before do
              mr_service = ProjectsService.new(@another_user,
                                               project,
                                               attributes_for(:merge_request,
                                                              source_project: project,
                                                              target_project: project)).merge_request
              @merge_request = mr_service.create

              params = { merge_request: { state_event: :merge } }

              clear_prepare_data

              collect_mails_data do
                ProjectsService.new(@another_user, project, params).merge_request(@merge_request).update
              end
            end

            it "only one message" do
              # FIXME. In test after merge merge request created new MR
              # I don't know what it is
              @mails_count.should == 2
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-merge_request-#{@merge_request.iid}"
              @email.body.should_not be_empty
            end
          end

          context "when close MR" do
            before do
              @merge_request = ProjectsService.new(@another_user, project, attributes_for(:merge_request, source_project: project, target_project: project)).merge_request.create
              params = { merge_request: { state_event: :close } }

              collect_mails_data do
                ProjectsService.new(@another_user, project, params).merge_request(@merge_request).update
              end
            end

            it "only one message" do
              # FIXME. In test after close merge request created new MR
              # I don't know what it is
              @mails_count.should == 2
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-merge_request-#{@merge_request.iid}"
              @email.body.should_not be_empty
            end
          end

          context "when reopen MR" do
            before do
              @merge_request.close
              params = { merge_request: { state_event: :reopen } }

              collect_mails_data do
                ProjectsService.new(@another_user, project, params).merge_request(@merge_request).update
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-merge_request-#{@merge_request.iid}"
              @email.body.should_not be_empty
            end
          end
        end
      end

      context "when event source - snippet" do
        context "when create snippet" do
          before do
            collect_mails_data do
              @snippet = create :project_snippet, project: project, author: @another_user
            end
          end

          it { pending "add (or delete) tests for snippets in project" }
          #it { @mails_count.should == 1 }
          #it { @email.from.first.should == @another_user.email }
          #it { @email.to.should be_nil }
          #it { @email.cc.should be_nil }
          #it { @email.bcc.count.should == 1 }
          #it { @email.bcc.first.should == @user.email }
          #it { @email.in_reply_to.should == "project-#{@old_path_with_namespace}" }
        end
      end

      context "when event source - project_hook" do
        context "create project_hook" do
          before do
            collect_mails_data do
              @project_hook = create :project_hook, project: project
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-project_hook-#{@project_hook.id}"
            @email.body.should_not be_empty
          end
        end

        context "when project_hook present in project" do
          before do
            @project_hook = create :project_hook, project: project
          end

          context "when update project_hook" do
            before do
              collect_mails_data do
                @project_hook.update_attributes(url: "#{@project_hook.url}/updated")
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-project_hook-#{@project_hook.id}"
              @email.body.should_not be_empty
            end
          end

          context "when remove project_hook" do
            before do
              collect_mails_data do
                ProjectsService.new(@another_user, project).delete_hook(@project_hook)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-project_hook-#{@project_hook.id}"
              @email.body.should_not be_empty
            end
          end
        end
      end

      context "when event source - protected_branch" do
        context "when protect branch" do
          before do
            collect_mails_data do
              ProjectsService.new(@another_user, project).repository.protect_branch("master")
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-branch-master"
            @email.body.should_not be_empty
          end
        end

        context "when unprotect branch" do
          before do
            @pb = project.protected_branches.create(name: "master")

            collect_mails_data do
              ProjectsService.new(@another_user, project).repository.unprotect_branch(@pb.name)
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-branch-#{@pb.name}"
            @email.body.should_not be_empty
          end
        end
      end

      context "when event source - service" do
        Service.implement_services.map {|s| s.new }.each do |service|
          context "and service is #{service.to_param}" do
            context "when create service" do
              before do
                collect_mails_data do
                  @service = create :"#{service.to_param}_service"
                end
              end

              it { pending "Add tests for service in projects" }
              #it { @mails_count.should == 1 }
              #it { @email.from.first.should == @another_user.email }
              #it { @email.to.should be_nil }
              #it { @email.cc.should be_nil }
              #it { @email.bcc.count.should == 1 }
              #it { @email.bcc.first.should == @user.email }
              #it { @email.in_reply_to.should == "project-#{@old_path_with_namespace}" }
            end
          end
        end
      end

      context "when event source - team" do
        before do
          @team = create :team, creator: @another_user
        end

        context "when assign team on project" do
          before do
            collect_mails_data do
              @rel = ProjectsService.new(@another_user, project, { team_ids: [@team.id] }).assign_team
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-team-#{@team.path}"
            @email.body.should_not be_empty
          end
        end

        context "when remove team from project" do
          before do
            @rel = ProjectsService.new(@another_user, project, { team_ids: [@team.id] }).assign_team

            collect_mails_data do
              ProjectsService.new(@another_user, project).resign_team(@team)
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-team-#{@team.path}"
            @email.body.should_not be_empty
          end
        end
      end

      context "when event source - users_project" do
        before do
          @user_1_to_project = create :user
          @user_2_to_project = create :user
        end

        context "when add users to project" do
          before do
            params = { user_ids: [@user_1_to_project.id], project_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              @rel = ProjectsService.new(@another_user, project, params).add_membership
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-user-#{@user_1_to_project.username}"
            @email.body.should_not be_empty
          end
        end

        context "when add many users to project" do
          before do
            params = { user_ids: [@user_1_to_project.id, @user_2_to_project.id], project_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              @rel = ProjectsService.new(@another_user, project, params).add_membership
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-members"
            @email.body.should_not be_empty
          end
        end

        context "when import users from another project" do
          before do
            @group = create :group, owner: @another_user

            params = { project: attributes_for(:empty_project, creator_id: @another_user.id, namespace_id: @group.id) }
            @first_project = ProjectsService.new(@another_user, params[:project]).create

            params = { project: attributes_for(:empty_project, creator_id: @another_user.id, namespace_id: @group.id) }
            @second_project = ProjectsService.new(@another_user, params[:project]).create

            params = { user_ids: [@user_1_to_project.id, @user_2_to_project.id], project_access: Gitlab::Access::DEVELOPER }
            ProjectsService.new(@another_user, @first_project, params).add_membership

            params = { source_project_id: @first_project.id }
            collect_mails_data do
              ProjectsService.new(@another_user, @second_project, params).import_memberships
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{@second_project.path_with_namespace}-members"
            @email.body.should_not be_empty
          end
        end

        context "when user in project" do
          before do
            params = { user_ids: [@user_1_to_project.id, @user_2_to_project.id], project_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              ProjectsService.new(@another_user, project, params).add_membership
            end
          end

          context "when update user access to project" do
            before do
              collect_mails_data do
                ProjectsService.new(@another_user, project, { team_member: { project_access: Gitlab::Access::MASTER } }).update_membership(@user_1_to_project)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-user-#{@user_1_to_project.username}"
              @email.body.should_not be_empty
            end
          end

          context "when update user access to project for many users" do
            before do
              collect_mails_data do
                ProjectsService.new(@another_user, project, { ids: [@user_1_to_project.id, @user_2_to_project.id], team_member: { project_access: Gitlab::Access::MASTER } }).batch_update_memberships
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-members"
              @email.body.should_not be_empty
            end
          end

          context "when update user access to project for every user, which was added scoupe" do
            before do
              collect_mails_data do
                ProjectsService.new(@another_user, project, { team_member: { project_access: Gitlab::Access::MASTER } }).update_membership(@user_1_to_project)
                ProjectsService.new(@another_user, project, { team_member: { project_access: Gitlab::Access::MASTER } }).update_membership(@user_2_to_project)
                ProjectsService.new(@another_user, project, { team_member: { project_access: Gitlab::Access::DEVELOPER } }).update_membership(@user_1_to_project)
                ProjectsService.new(@another_user, project, { team_member: { project_access: Gitlab::Access::DEVELOPER } }).update_membership(@user_2_to_project)
              end
            end

            it "only one message" do
              @mails_count.should == 4
            end
          end

          context "when remove user from project" do
            before do
              collect_mails_data do
                ProjectsService.new(@another_user, project).remove_membership(@user_2_to_project)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-user-#{@user_2_to_project.username}"
              @email.body.should_not be_empty
            end
          end

          context "when remove many users from project" do
            before do
              collect_mails_data do
                ProjectsService.new(@another_user, project, { ids: [@user_1_to_project.id, @user_2_to_project.id]}).batch_remove_memberships
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-members"
              @email.body.should_not be_empty
            end
          end

        end
      end

      context "when event source - push action" do
        before do
          @oldrev = '93efff945215a4407afcaf0cba15ac601b56df0d'
          @newrev = 'b19a04f53caeebf4fe5ec2327cb83e9253dc91bb'
          @ref = 'refs/heads/master'
        end

        context "when pushed code" do
          before do
            collect_mails_data do
              GitPushService.new(@another_user, project, @oldrev, @newrev, @ref).execute
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-#{@oldrev}"
            @email.body.should_not be_empty
          end
        end

        context "when pushed new branch" do
          before do
            @oldrev = '0000000000000000000000000000000000000000'
            collect_mails_data do
              GitPushService.new(@another_user, project, @oldrev, @newrev, @ref).execute
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should =~ /project-#{project.path_with_namespace}-push-action-/
          end
        end

        context "when pushed new tag" do
          before do
            @oldrev = '0000000000000000000000000000000000000000'
            @ref = 'refs/tags/v2.2.0'
            collect_mails_data do
              GitPushService.new(@another_user, project, @oldrev, @newrev, @ref).execute
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should =~ /project-#{project.path_with_namespace}-push-action-/
          end
        end

        context "when remove branch via push" do
          before do
            @newrev = '0000000000000000000000000000000000000000'
            collect_mails_data do
              GitPushService.new(@another_user, project, @oldrev, @newrev, @ref).execute
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should =~ /project-#{project.path_with_namespace}-push-action-/
          end
        end

        context "when remove tag via push" do
          before do
            @newrev = '0000000000000000000000000000000000000000'
            @ref = 'refs/tags/v2.2.0'
            collect_mails_data do
              GitPushService.new(@another_user, project, @oldrev, @newrev, @ref).execute
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should =~ /project-#{project.path_with_namespace}-push-action-/
          end
        end

        context "when pushed revert" do
          before do
            @oldrev = 'c844723a2404f97421c14ed48bbb8fec9fa8f6b7'
            @newrev  = 'aacbb9a9a5e317728a985674a61279781fb3ca26'

            collect_mails_data do
              GitPushService.new(@another_user, project, @oldrev, @newrev, @ref).execute
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end
          #
          # it "correct email" do
          #   @email.from.first.should == @another_user.email
          #   @email.to.should be_nil
          #   @email.cc.should be_nil
          #   @email.bcc.count.should == 1
          #   @email.bcc.first.should == @user.email
          #   @email.in_reply_to.should == "project-#{project.path_with_namespace}-#{@oldrev}"
          #   @email.body.should_not be_empty
          # end
        end
      end
    end
  end

  describe "Group mails" do
    context "when user subscribed only on group" do
      before do
        Gitlab::Event::Subscription.create_auto_subscription(@user, :group)
      end

      context "when event source - group " do
        context "when create group" do
          before do
            collect_mails_data do
              params = attributes_for :group, owner: @another_user.id
              @group = GroupsService.new(@another_user, params).create
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "group-#{@group.path}"
            @email.body.should_not be_empty
          end
        end

        context "when group present" do
          before do
            params = attributes_for :group, owner: @another_user.id
            @group = GroupsService.new(@another_user, params).create
          end

          context "when update group" do
            before do
              collect_mails_data do
                @group.update_attributes(attributes_for(:group))
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@group.path}"
              @email.body.should_not be_empty
            end
          end

          context "when remove group" do
            before do
              collect_mails_data do
                clean_destroy do
                  GroupsService.new(@another_user, @group).delete
                end
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@group.path}"
              @email.body.should_not be_empty
            end
          end
        end
      end

      context "when group present" do
        before do
          params = attributes_for :group, owner: @another_user.id
          @group = GroupsService.new(@another_user, params).create
        end

        context "when event source - project" do
          context "when create project in group" do
            before do
              params = { project: attributes_for(:project, namespace_id: @group.id) }
              collect_mails_data do
                @project = ProjectsService.new(@another_user, params[:project]).create
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{@project.path_with_namespace}"
              @email.body.should_not be_empty
            end
          end

          context "when project moved to group" do
            before do
              @project = ProjectsService.new(@another_user, attributes_for(:project, namespace_id: nil)).create
              params = attributes_for :group, owner: @another_user.id
              @another_group = GroupsService.new(@another_user, params).create
              params = { project: { namespace_id: @another_group.id }}
              collect_mails_data do
                ProjectsService.new(@another_user, @project, params).transfer
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@another_group.path}-project-#{@project.path_with_namespace}"
              @email.body.should_not be_empty
            end
          end

          context "when project moved to group" do
            before do
              @another_group = create :group, owner: @another_user
              @project = create :project, namespace_id: @group.id
              params = { project: { namespace_id: @another_group.id }}
              collect_mails_data do
                ProjectsService.new(@another_user, @project, params).transfer
              end
            end

            it "only one message" do
              # Move mail into project creator
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@another_group.path}-project-#{@project.path_with_namespace}"
              @email.body.should_not be_empty
            end
          end

          context "when project removed in group" do
            before do
              @project = create :project, namespace_id: @group.id
              collect_mails_data do
                ProjectsService.new(@another_user, @project).delete
              end
            end

            it "only one message" do
              pending
              @mails_count.should == 1
            end

            it "correct email" do
              pending
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@group.path}-project-#{@project.path_with_namespace}"
              @email.body.should_not be_empty
            end
          end
        end

        context "when event source - team" do
          before do
            @team = create :team, creator: @another_user
          end

          context "when team assigned to group" do
            before do
              params = { team_ids: [@team.id] }
              collect_mails_data do
                GroupsService.new(@another_user, @group, params).assign_team
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@group.path}-team-#{@team.path}"
              @email.body.should_not be_empty
            end
          end

          context "when many teams assigned to group" do
            before do
              @second_team = create :team, creator: @another_user
              params = { team_ids: [@team.id, @second_team.id] }
              collect_mails_data do
                GroupsService.new(@another_user, @group, params).assign_team
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@group.path}-teams"
              @email.body.should_not be_empty
            end
          end
          context "when team removed from group" do
            before do
              params = { team_ids: [@team.id] }
              GroupsService.new(@another_user, @group, params).assign_team
              collect_mails_data do
                GroupsService.new(@another_user, @group).resign_team(@team)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@group.path}-team-#{@team.path}"
              @email.body.should_not be_empty
            end
          end
        end

        context "when event source - users_group" do
          before do
            @user_1_to_group = create :user
            @user_2_to_group = create :user
          end

          context "when add users to group" do
            before do
              params = { user_ids: [@user_1_to_group.id], group_access: Gitlab::Access::DEVELOPER }
              collect_mails_data do
                GroupsService.new(@another_user, @group, params).add_membership
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@group.path}-user-#{@user_1_to_group.username}"
              @email.body.should_not be_empty
            end
          end

          context "when add many users to group" do
            before do
              params = { user_ids: [@user_1_to_group.id, @user_2_to_group.id], group_access: Gitlab::Access::DEVELOPER }
              collect_mails_data do
                GroupsService.new(@another_user, @group, params).add_membership
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@group.path}-members"
              @email.body.should_not be_empty
            end
          end

          context "when user in group" do
            before do
              params = { user_ids: [@user_1_to_group.id, @user_2_to_group.id], group_access: Gitlab::Access::DEVELOPER }
              GroupsService.new(@another_user, @group, params).add_membership
            end

            context "when update user access to group" do
              before do
                collect_mails_data do
                  GroupsService.new(@another_user, @group, {group_access: Gitlab::Access::MASTER }).update_membership(@user_1_to_group)
                end
              end

              it "only one message" do
                @mails_count.should == 1
              end

              it "correct email" do
                @email.from.first.should == @another_user.email
                @email.to.should be_nil
                @email.cc.should be_nil
                @email.bcc.count.should == 1
                @email.bcc.first.should == @user.email
                @email.in_reply_to.should == "group-#{@group.path}-user-#{@user_1_to_group.username}"
                @email.body.should_not be_empty
              end
            end

            context "when remove user from group" do
              before do
                collect_mails_data do
                  GroupsService.new(@another_user, @group).remove_membership(@user_2_to_group)
                end
              end

              it "only one message" do
                @mails_count.should == 1
              end

              it "correct email" do
                @email.from.first.should == @another_user.email
                @email.to.should be_nil
                @email.cc.should be_nil
                @email.bcc.count.should == 1
                @email.bcc.first.should == @user.email
                @email.in_reply_to.should == "group-#{@group.path}-user-#{@user_2_to_group.username}"
                @email.body.should_not be_empty
              end
            end
          end
        end
      end
    end

    context "when user subscribed on adjacent notifications" do
      before do
        @user.notification_setting.adjacent_changes = true
        @user.notification_setting.save
        Gitlab::Event::Subscription.create_auto_subscription(@user, :group)
        @group = create :group, owner: @another_user
        Gitlab::Event::Subscription.create_auto_subscription(@user, :project, @group)
      end

      context "when update project" do
        before do
          params = attributes_for(:project, namespace_id: @group.id)
          @project = ProjectsService.new(@another_user, params).create
          params = { project: attributes_for(:project) }

          collect_mails_data do
            ProjectsService.new(@another_user, @project, params).update
          end
        end

        it "only one message" do
          @mails_count.should == 1
        end

        it "correct email" do
          @email.from.first.should == @another_user.email
          @email.to.should be_nil
          @email.cc.should be_nil
          @email.bcc.count.should == 1
          @email.bcc.first.should == @user.email
          @email.in_reply_to.should == "project-#{@project.path_with_namespace}"
          @email.body.should_not be_empty
        end
      end

      context "when update project with subscription on project" do
        before do
          Gitlab::Event::Subscription.create_auto_subscription(@user, :project)

          params = attributes_for(:project, namespace_id: @group.id)
          @project = ProjectsService.new(@another_user, params).create

          params = { project: attributes_for(:project) }

          collect_mails_data do
            ProjectsService.new(@another_user, @project, params).update
          end
        end

        it "subscriptions count == 5" do
          Event::Subscription.count.should == 2
        end

        it "only one message" do
          @mails_count.should == 1
        end

        it "correct email" do
          @email.from.first.should == @another_user.email
          @email.to.should be_nil
          @email.cc.should be_nil
          @email.bcc.count.should == 1
          @email.bcc.first.should == @user.email
          @email.in_reply_to.should == "project-#{@project.path_with_namespace}"
          @email.body.should_not be_empty
        end
      end
    end
  end

  describe "Teams emails" do
    before do
      Gitlab::Event::Subscription.create_auto_subscription(@user, :team)
    end

    context "when event source - team" do
      context "when create team" do
        before do
          collect_mails_data do
            params = attributes_for :team, creator: @another_user.id
            @team = TeamsService.new(@another_user, params).create
          end
        end

        it "only one message" do
          @mails_count.should == 1
        end

        it "correct email" do
          @email.from.first.should == @another_user.email
          @email.to.should be_nil
          @email.cc.should be_nil
          @email.bcc.count.should == 1
          @email.bcc.first.should == @user.email
          @email.in_reply_to.should == "team-#{@team.path}"
          @email.body.should_not be_empty
        end
      end

      context "when team present" do
        before do
          params = attributes_for :team, creator: @another_user.id
          @team = TeamsService.new(@another_user, params).create
        end

        context "when update team" do
          before do
            collect_mails_data do
              @team.update(attributes_for(:team))
            end
          end
          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "team-#{@team.path}"
            @email.body.should_not be_empty
          end
        end

        context "when destroy team" do
          before do
            collect_mails_data do
              clean_destroy do
                TeamsService.new(@another_user, @team).delete
              end
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "team-#{@team.path}"
            @email.body.should_not be_empty
          end
        end
      end
    end

    context "when team present" do
      before do
        params = attributes_for :team, creator: @another_user.id
        @team = TeamsService.new(@another_user, params).create
      end

      context "when event source - team_user_relationship" do
        context "we add user to team" do
          before do
            @user_to_team = create :user
            params = { user_ids: [@user_to_team.id], team_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              TeamsService.new(@another_user, @team, params).add_memberships
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "team-#{@team.path}-user-#{@user_to_team.username}"
            @email.body.should_not be_empty
          end
        end

        context "user present in team" do
          before do
            @user_in_team = create :user
            params = { user_ids: [@user_in_team.id], team_access: Gitlab::Access::DEVELOPER }
            TeamsService.new(@another_user, @team, params).add_memberships
          end

          context "we update access in team" do
            before do
              params = { team_access: Gitlab::Access::MASTER }
              collect_mails_data do
                TeamsService.new(@another_user, @team, params).update_memberships(@user_in_team)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "team-#{@team.path}-user-#{@user_in_team.username}"
              @email.body.should_not be_empty
            end
          end

          context "we remove user from team" do
            before do
              collect_mails_data do
                TeamsService.new(@another_user, @team).delete_membership(@user_in_team)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "team-#{@team.path}-user-#{@user_in_team.username}"
              @email.body.should_not be_empty
            end
          end
        end
      end

      context "when event source - team_project_relationship" do
        context "we assign team to project" do
          before do
            @project_to_team = create :project, creator: @another_user
            params = { project_ids: [@project_to_team.id] }

            collect_mails_data do
              TeamsService.new(@another_user, @team, params).assign_on_projects
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "team-#{@team.path}-project-#{@project_to_team.path_with_namespace}"
            @email.body.should_not be_empty
          end
        end

        context "we resign team from project" do
          before do
            @project_in_team = create :project, creator: @another_user
            params = { project_ids: [@project_in_team.id] }
            TeamsService.new(@another_user, @team, params).assign_on_projects

            collect_mails_data do
              TeamsService.new(@another_user, @team).resign_from_projects(@project_in_team)
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "team-#{@team.path}-project-#{@project_in_team.path_with_namespace}"
            @email.body.should_not be_empty
          end
        end
      end

      context "when event source - team_group_relationship" do
        context "when assign team to group" do
          before do
            Gitlab::Event::Subscription.create_auto_subscription(@user, :group)
            Gitlab::Event::Subscription.create_auto_subscription(@user, :project)

            double(create :project, namespace: group, creator: @another_user)

            user1 = create :user
            user2 = create :user

            params = { user_ids: "#{user1.id}", team_access: Gitlab::Access::MASTER }
            TeamsService.new(@another_user, @team, params).add_memberships

            params = { user_ids: "#{user2.id}", team_access: Gitlab::Access::DEVELOPER }
            TeamsService.new(@another_user, @team, params).add_memberships

            params = { group_ids: [group.id] }
            collect_mails_data do
              TeamsService.new(@another_user, @team, params).assign_on_groups
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            # FIXME check
            #@email.in_reply_to.should == "team-#{@team.path}-group-#{group.path}"
            @email.body.should_not be_empty
          end
        end

        context "assign team to group with subscriptions on projects only" do
          before do
            Gitlab::Event::Subscription.create_auto_subscription(@user, :project)

            @project1 = create :empty_project, namespace: group, creator: @another_user
            @project2 = create :empty_project, namespace: group, creator: @another_user

            user1 = create :user
            params = { user_ids: "#{user1.id}", team_access: Gitlab::Access::MASTER }
            TeamsService.new(@another_user, @team, params).add_memberships

            user2 = create :user
            params = { user_ids: "#{user2.id}", team_access: Gitlab::Access::DEVELOPER }
            TeamsService.new(@another_user, @team, params).add_memberships

            params = { group_ids: "#{group.id}" }
            collect_mails_data do
              TeamsService.new(@another_user, @team, params).assign_on_groups
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "team-#{@team.path}-group-#{group.path}"
            @email.body.should_not be_empty
          end
        end

        context "resign team from group" do
          before do
            params = { group_ids: "#{group.id}" }
            TeamsService.new(@another_user, @team, params).assign_on_groups

            collect_mails_data do
              TeamsService.new(@another_user, @team).resign_from_groups(group)
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "team-#{@team.path}-group-#{group.path}"
            @email.body.should_not be_empty
          end
        end
      end
    end
  end

  describe "Users mails" do
    before do
      Gitlab::Event::Subscription.create_auto_subscription(@user, :user)
    end

    context "when event source - user" do
      context "when create user" do
        before do
          collect_mails_data do
            @watched_user = create :user
          end
        end

        it "only one message" do
          @mails_count.should == 1
        end

        it "correct email" do
          @email.from.first.should == @another_user.email
          @email.to.should be_nil
          @email.cc.should be_nil
          @email.bcc.count.should == 1
          @email.bcc.first.should == @user.email
          @email.in_reply_to.should == "user-#{@watched_user.username}"
          @email.body.should_not be_empty
        end

      end

      context "when user present" do
        before do
          @watched_user = create :user
        end

        context "when activate user" do
          before do
            @watched_user.block

            collect_mails_data do
              @watched_user.activate
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "user-#{@watched_user.username}"
            @email.body.should_not be_empty
          end
        end

        context "when update user" do
          before do
            collect_mails_data do
              @watched_user.update_attributes({ name: @watched_user.name + "_updated" })
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "user-#{@watched_user.username}"
            @email.body.should_not be_empty
          end
        end

        context "when remove user" do
          before do
            collect_mails_data do
              clean_destroy do
                UsersService.new(@another_user, @watched_user).delete
              end
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "user-#{@watched_user.username}"
            @email.body.should_not be_empty
          end
        end

        context "when block user" do
          context "when user wasn't in group or project or team" do
            before do
              collect_mails_data do
                UsersService.new(@another_user, @watched_user).block
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "user-#{@watched_user.username}"
              @email.body.should_not be_empty
            end
          end

          context "when user was in 1 project, 1 group and 1 team" do
            before do
              @team = create :team, creator: @another_user
              @team.add_users([@watched_user.id], Gitlab::Access::MASTER)

              @group = create :group, owner: @another_user
              @group.add_users([@watched_user.id], Gitlab::Access::MASTER)

              @project = ProjectsService.new(@another_user, attributes_for(:project, namespace_id: @group)).create
              @project.team << [@watched_user, Gitlab::Access::MASTER]

              collect_mails_data do
                UsersService.new(@another_user, @watched_user).block
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "user-#{@watched_user.username}"
              @email.body.should_not be_empty
            end
          end
        end
      end
    end

    context "actions with present user" do
      before do
        @watched_user = create :user
      end

      context "when event source - users_project" do
        context "when add users to project" do
          before do
            params = { user_ids: [@watched_user.id], project_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              @rel = ProjectsService.new(@another_user, project, params).add_membership
            end
          end

          it "only one message" do
            pending "Fixme"
            @mails_count.should == 1
          end

          it "correct email" do
            pending "Fixme"
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-user-#{@watched_user.username}"
            @email.body.should_not be_empty
          end
        end

        context "when user in project" do
          before do
            params = { user_ids: [@watched_user.id], project_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              ProjectsService.new(@another_user, project, params).add_membership
            end
          end

          context "when update user access to project" do
            before do
              collect_mails_data do
                ProjectsService.new(@another_user, project, { team_member: { project_access: Gitlab::Access::MASTER } }).update_membership(@watched_user)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-user-#{@watched_user.username}"
              @email.body.should_not be_empty
            end
          end

          context "when remove user from project" do
            before do
              collect_mails_data do
                ProjectsService.new(@another_user, project).remove_membership(@watched_user)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "project-#{project.path_with_namespace}-user-#{@watched_user.username}"
              @email.body.should_not be_empty
            end
          end
        end

      end

      context "when event source - users_group" do
        before do
          @group = create :group, owner: @another_user
        end

        context "when add users to group" do
          before do
            params = { user_ids: [@watched_user.id], group_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              GroupsService.new(@another_user, @group, params).add_membership
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "group-#{@group.path}-user-#{@watched_user.username}"
            @email.body.should_not be_empty
          end
        end

        context "when user in group" do
          before do
            params = { user_ids: [@watched_user.id], group_access: Gitlab::Access::DEVELOPER }
            GroupsService.new(@another_user, @group, params).add_membership
          end

          context "when update user access to group" do
            before do
              collect_mails_data do
                GroupsService.new(@another_user, @group, {group_access: Gitlab::Access::MASTER }).update_membership(@watched_user)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@group.path}-user-#{@watched_user.username}"
              @email.body.should_not be_empty
            end
          end

          context "when remove user from group" do
            before do
              collect_mails_data do
                GroupsService.new(@another_user, @group).remove_membership(@watched_user)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "group-#{@group.path}-user-#{@watched_user.username}"
              @email.body.should_not be_empty
            end
          end
        end
      end

      context "when event source - team_user_relationship" do
        before do
          @team = create :team, creator: @another_user
        end

        context "we add user to team" do
          before do
            params = { user_ids: [@watched_user.id], team_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              TeamsService.new(@another_user, @team, params).add_memberships
            end
          end

          it "only one message" do
            @mails_count.should == 1
          end

          it "correct email" do
            @email.from.first.should == @another_user.email
            @email.to.should be_nil
            @email.cc.should be_nil
            @email.bcc.count.should == 1
            @email.bcc.first.should == @user.email
            @email.in_reply_to.should == "team-#{@team.path}-user-#{@watched_user.username}"
            @email.body.should_not be_empty
          end
        end

        context "user present in team" do
          before do
            @user_in_team = create :user
            params = { user_ids: [@watched_user.id], team_access: Gitlab::Access::DEVELOPER }
            TeamsService.new(@another_user, @team, params).add_memberships
          end

          context "we update access in team" do
            before do
              params = { team_access: Gitlab::Access::MASTER }
              collect_mails_data do
                TeamsService.new(@another_user, @team, params).update_memberships(@watched_user)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "team-#{@team.path}-user-#{@watched_user.username}"
              @email.body.should_not be_empty
            end
          end

          context "we remove user from team" do
            before do
              collect_mails_data do
                TeamsService.new(@another_user, @team).delete_membership(@watched_user)
              end
            end

            it "only one message" do
              @mails_count.should == 1
            end

            it "correct email" do
              @email.from.first.should == @another_user.email
              @email.to.should be_nil
              @email.cc.should be_nil
              @email.bcc.count.should == 1
              @email.bcc.first.should == @user.email
              @email.in_reply_to.should == "team-#{@team.path}-user-#{@watched_user.username}"
              @email.body.should_not be_empty
            end
          end
        end
      end
    end
  end
end
