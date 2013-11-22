require "spec_helper"

describe EventNotificationMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  def clear_prepare_data
    Event.destroy_all
    Event::Subscription::Notification.destroy_all;
    ActionMailer::Base.deliveries.clear;
    EventHierarchyWorker.reset;
  end

  def collect_mails_data
    clear_prepare_data
    yield
    @mails = ActionMailer::Base.deliveries
    @mails_count = @mails.count
    @email = @mails.first
  end

  def clean_destroy
    EventSubscriptionCleanWorker.any_instance.stub(:perform).and_return(true)
    yield
  end

  let(:group)   { g  = create :group,             owner:   @another_user;                                     clear_prepare_data; g }
  let(:project) { pr = create :project_with_code, creator: @another_user, namespace: group; clear_prepare_data; pr }

  before do
    ActiveRecord::Base.observers.enable(:user_observer) do
      @user = create :user
      @another_user = create :user
      @commiter_user = create :user, { email: "dmitriy.zaporozhets@gmail.com" }
    end

    @user.create_notification_setting(brave: true)
    RequestStore.store[:current_user] = @another_user
    clear_prepare_data
    ActiveRecord::Base.observers.enable :all
  end

  #after do
    #clean_destroy do
      #@commiter_user.destroy
      #@another_user.destroy
      #@user.destroy
    #end
  #end

  describe "Project mails" do
    before { SubscriptionService.subscribe(@user, :all, :project, :all) }

    context "when event source - project " do
      context "when create project" do
        before { collect_mails_data { @project = Projects::CreateContext.new(@another_user, attributes_for(:project)).execute } }

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
            @project_for_update = Projects::CreateContext.new(@another_user, attributes_for(:project)).execute

            collect_mails_data do
              Projects::UpdateContext.new(@another_user, @project_for_update, { project: attributes_for(:project) }).execute
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
            @project_for_transfer = Projects::CreateContext.new(@another_user, attributes_for(:project)).execute
            @old_path_with_namespace = @project_for_transfer.path_with_namespace
            @group = create :group, owner: @another_user

            collect_mails_data do
              ::Projects::TransferContext.new(@another_user, @project_for_transfer, @group).execute
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
            @project_in_group = Projects::CreateContext.new(@another_user, params[:project]).execute
            @old_path_with_namespace = @project_in_group.path_with_namespace

            collect_mails_data do
              ::Projects::TransferContext.new(@another_user, @project_in_group, @new_group).execute
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
            @project_in_group = Projects::CreateContext.new(@another_user, params[:project]).execute
            @old_path_with_namespace = @project_in_group.path_with_namespace

            collect_mails_data do
              ::Projects::TransferContext.new(@another_user, @project_in_group, @another_user.namespace).execute
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

        context "when import users from another project" do
          it { pending "add (or delete) when import users from another project" }
        end

        context "when destroy project" do
          before do
            @project_for_destroy = Projects::CreateContext.new(@another_user, attributes_for(:project)).execute
            @old_path_with_namespace = @project_for_destroy.path_with_namespace
            collect_mails_data do
              clean_destroy do
                ::Projects::RemoveContext.new(@another_user, @project_for_destroy).execute
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
      before { SubscriptionService.subscribe(@user, :all, project, :all) if Event::Subscription.by_target(project).empty? }

      context "when event source - issue" do
        context "when create issue" do
          before do
            collect_mails_data do
              @issue = create :issue, project: project
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
                Projects::Issues::UpdateContext.new(@another_user, project, @issue, params).execute
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
                Projects::Issues::UpdateContext.new(@another_user, project, @issue, params).execute
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
        context "when create note on wall" do
          before do
            collect_mails_data do
              @note = Projects::Notes::CreateContext.new(@another_user, project, { note: attributes_for(:note) }).execute
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
            @email.in_reply_to.should == "project-#{project.path_with_namespace}-wall"
          end
        end

        context "when update note" do
          before do
            @note = Projects::Notes::CreateContext.new(@another_user, project, { note: attributes_for(:note) }).execute

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
              @note = Projects::Notes::CreateContext.new(@another_user, project, note: attributes_for(:note_on_commit)).execute
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

        context "when create note on commit diff" do
          before do
            project.team << [@commiter_user, 40]
            params = { note: attributes_for(:note_on_commit_diff) }

            collect_mails_data do
              Projects::Notes::CreateContext.new(@another_user, project, params).execute
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
            @merge_request = create :merge_request, source_project: project, target_project: project
          end

          context "when create note on MR wall" do
            before do
              params = { note: attributes_for(:note_on_merge_request, noteable: @merge_request) }
              collect_mails_data do
                Projects::Notes::CreateContext.new(@another_user, project, params).execute
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
                Projects::Notes::CreateContext.new(@another_user, project, params).execute
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
              @merge_request = create :merge_request, source_project: project, target_project: project
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
              @merge_request = create :merge_request, source_project: project, target_project: project, assignee: @user
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
            @merge_request = create :merge_request, source_project: project, target_project: project
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
                ::Projects::MergeRequests::UpdateContext.new(@user, project, @merge_request, params).execute
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

          context "when reassignee MR" do
            before do
              params = {
                merge_request: {
                  assignee_id: @another_user.id
                }
              }

              ::Projects::MergeRequests::UpdateContext.new(@user, project, @merge_request, params).execute

              params = {
                merge_request: {
                  assignee_id: @user.id
                }
              }

              collect_mails_data do
                ::Projects::MergeRequests::UpdateContext.new(@user, project, @merge_request, params).execute
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
              @merge_request = create :merge_request, source_project: project, target_project: project
              params = { merge_request: { state_event: :merge } }

              collect_mails_data do
                Projects::MergeRequests::UpdateContext.new(@another_user, project, @merge_request, params).execute
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

          context "when close MR" do
            before do
              @merge_request = create :merge_request, source_project: project, target_project: project
              params = { merge_request: { state_event: :close } }

              collect_mails_data do
                Projects::MergeRequests::UpdateContext.new(@another_user, project, @merge_request, params).execute
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

          context "when reopen MR" do
            before do
              @merge_request.close
              params = { merge_request: { state_event: :reopen } }

              collect_mails_data do
                Projects::MergeRequests::UpdateContext.new(@another_user, project, @merge_request, params).execute
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
                Projects::ProjectHooks::RemoveContext.new(@another_user, project, @project_hook).execute
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
              @pb = create :protected_branch, project: project, name: "master"
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

        context "when unprotect branch" do
          before do
            @pb = create :protected_branch, project: project, name: "master"

            collect_mails_data do
              Projects::ProtectedBranchs::RemoveContext.new(@another_user, project, @pb).execute
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
              @rel = Projects::Teams::CreateRelationContext.new(@another_user, project, { team_ids: [@team.id] }).execute
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
            @rel = Projects::Teams::CreateRelationContext.new(@another_user, project, { team_ids: [@team.id] }).execute

            collect_mails_data do
              Projects::Teams::RemoveRelationContext.new(@another_user, project, @team).execute
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
            params = { user_ids: [@user_1_to_project.id, @user_2_to_project.id], project_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              @rel = Projects::Users::CreateRelationContext.new(@another_user, project, params).execute
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

        context "when user in project" do
          before do
            params = { user_ids: [@user_1_to_project.id, @user_2_to_project.id], project_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              Projects::Users::CreateRelationContext.new(@another_user, project, params).execute
            end
          end

          context "when update user access to project" do
            before do
              collect_mails_data do
                Projects::Users::UpdateRelationContext.new(@another_user, project, @user_1_to_project, { team_member: { project_access: Gitlab::Access::MASTER } }).execute
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

          context "when remove user from project" do
            before do
              collect_mails_data do
                Projects::Users::RemoveRelationContext.new(@another_user, project, @user_2_to_project).execute
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
        end
      end

      context "when event source - push action" do
        #include FreezingEmail::Rspec

        before do
          @service = GitPushService.new
          @oldrev = 'b98a310def241a6fd9c9a9a3e7934c48e498fe81'
          @newrev = 'b19a04f53caeebf4fe5ec2327cb83e9253dc91bb'
          @ref = 'refs/heads/master'
          project.save
        end

        context "when pushed code" do
          before do
            collect_mails_data do
              @service.execute(project, @another_user, @oldrev, @newrev, @ref)
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
              @service.execute(project, @another_user, @oldrev, @newrev, @ref)
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
              @service.execute(project, @another_user, @oldrev, @newrev, @ref)
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
              @service.execute(project, @another_user, @oldrev, @newrev, @ref)
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
              @service.execute(project, @another_user, @oldrev, @newrev, @ref)
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
      end
    end
  end

  describe "Group mails" do
    context "when user subscribed only on group" do
      before do
        SubscriptionService.subscribe(@user, :all, :group, :all)
      end

      context "when event source - group " do
        context "when create group" do
          before do
            collect_mails_data do
              @group = create :group, owner: @another_user
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
            @group = create :group, owner: @another_user
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
                  Groups::RemoveContext.new(@another_user, @group).execute
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
          @group = create :group, owner: @another_user
        end

        context "when event source - project" do
          context "when create project in group" do
            before do
              params = { project: attributes_for(:project, namespace_id: @group.id) }
              collect_mails_data do
                @project = ::Projects::CreateContext.new(@another_user, params[:project]).execute
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
              @project = Projects::CreateContext.new(@another_user, attributes_for(:project, namespace_id: nil)).execute
              @another_group = create :group, owner: @another_user
              collect_mails_data do
                Projects::TransferContext.new(@another_user, @project, @another_group).execute
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
              collect_mails_data do
                Projects::TransferContext.new(@another_user, @project, @another_group).execute
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

          context "when project removed in group" do
            before do
              @project = create :project, namespace_id: @group.id
              collect_mails_data do
                Projects::RemoveContext.new(@another_user, @project).execute
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
                Groups::Teams::CreateRelationContext.new(@another_user, @group, params).execute
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

          context "when team removed from group" do
            before do
              params = { team_ids: [@team.id] }
              Groups::Teams::CreateRelationContext.new(@another_user, @group, params).execute
              collect_mails_data do
                Groups::Teams::RemoveRelationContext.new(@another_user, @group, @team).execute
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
              params = { user_ids: [@user_1_to_group.id, @user_2_to_group.id], group_access: Gitlab::Access::DEVELOPER }
              collect_mails_data do
                Groups::Users::CreateRelationContext.new(@another_user, @group, params).execute
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

          context "when user in group" do
            before do
              params = { user_ids: [@user_1_to_group.id, @user_2_to_group.id], group_access: Gitlab::Access::DEVELOPER }
              Groups::Users::CreateRelationContext.new(@another_user, @group, params).execute
            end

            context "when update user access to group" do
              before do
                collect_mails_data do
                  Groups::Users::UpdateRelationContext.new(@another_user, @group, @user_1_to_group, {group_access: Gitlab::Access::MASTER }).execute
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
                  Groups::Users::RemoveRelationContext.new(@another_user, @group, @user_2_to_group).execute
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
        SubscriptionService.subscribe(@user, :all, :group, :all)
        @group = create :group, owner: @another_user
        SubscriptionService.subscribe(@user, :all, @group, :project)
      end

      context "when update project" do
        before do
          params = attributes_for(:project, namespace_id: @group.id)
          @project = Projects::CreateContext.new(@another_user, params).execute
          params = { project: attributes_for(:project) }

          collect_mails_data do
            Projects::UpdateContext.new(@another_user, @project, params).execute
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
          SubscriptionService.subscribe(@user, :all, :project, :all)

          params = attributes_for(:project, namespace_id: @group.id)
          @project = Projects::CreateContext.new(@another_user, params).execute

          params = { project: attributes_for(:project) }

          collect_mails_data do
            Projects::UpdateContext.new(@another_user, @project, params).execute
          end
        end

        it "subscriptions count == 5" do
          Event::Subscription.count.should == 5
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
      SubscriptionService.subscribe(@user, :all, :team, :all)
    end

    context "when event source - team" do
      context "when create team" do
        before do
          collect_mails_data do
            @team = create :team, creator: @another_user
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
          @team = create :team, creator: @another_user
        end

        context "when update team" do
          before do
            collect_mails_data do
              @team.update_attributes(attributes_for(:team))
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
                Teams::RemoveContext.new(@another_user, @team).execute
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
        @team = create :team, creator: @another_user
      end

      context "when event source - team_user_relationship" do
        context "we add user to team" do
          before do
            @user_to_team = create :user
            params = { user_ids: [@user_to_team.id], team_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              Teams::Users::CreateRelationContext.new(@another_user, @team, params).execute
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
            Teams::Users::CreateRelationContext.new(@another_user, @team, params).execute
          end

          context "we update access in team" do
            before do
              params = { team_access: Gitlab::Access::MASTER }
              collect_mails_data do
                Teams::Users::UpdateRelationContext.new(@another_user, @team, @user_in_team, params).execute
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
                Teams::Users::RemoveRelationContext.new(@another_user, @team, @user_in_team).execute
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
              Teams::Projects::CreateRelationContext.new(@another_user, @team, params).execute
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
            Teams::Projects::CreateRelationContext.new(@another_user, @team, params).execute

            collect_mails_data do
              Teams::Projects::RemoveRelationContext.new(@another_user, @team, @project_in_team).execute
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
            SubscriptionService.subscribe(@user, :all, :group, :all)
            SubscriptionService.subscribe(@user, :all, :project, :all)

            double(create :project, namespace: group, creator: @another_user)

            user1 = create :user
            user2 = create :user

            params = { user_ids: "#{user1.id}", team_access: Gitlab::Access::MASTER }
            Teams::Users::CreateRelationContext.new(@another_user, @team, params)

            params = { user_ids: "#{user2.id}", team_access: Gitlab::Access::DEVELOPER }
            Teams::Users::CreateRelationContext.new(@another_user, @team, params)

            params = { group_ids: [group.id] }
            collect_mails_data do
              Teams::Groups::CreateRelationContext.new(@another_user, @team, params).execute
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

        context "assign team to group with subscriptions on projects only" do
          before do
            SubscriptionService.subscribe(@user, :all, :project, :all)

            @project1 = create :project, namespace: group, creator: @another_user
            @project2 = create :project, namespace: group, creator: @another_user

            user1 = create :user
            params = { user_ids: "#{user1.id}", team_access: Gitlab::Access::MASTER }
            Teams::Users::CreateRelationContext.new(@another_user, @team, params)

            user2 = create :user
            params = { user_ids: "#{user2.id}", team_access: Gitlab::Access::DEVELOPER }
            Teams::Users::CreateRelationContext.new(@another_user, @team, params)

            params = { group_ids: "#{group.id}" }
            collect_mails_data do
              Teams::Groups::CreateRelationContext.new(@another_user, @team, params).execute
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
            Teams::Groups::CreateRelationContext.new(@another_user, @team, params).execute

            collect_mails_data do
              Teams::Groups::RemoveRelationContext.new(@another_user, @team, group).execute
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
      SubscriptionService.subscribe(@user, :all, :user, :all)
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
                Users::RemoveContext.new(@another_user, @watched_user).execute
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
                Users::BlockContext.new(@another_user, @watched_user).execute
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

              @project = Projects::CreateContext.new(@another_user, attributes_for(:project, namespace_id: @group)).execute
              @project.team << [@watched_user, Gitlab::Access::MASTER]

              collect_mails_data do
                Users::BlockContext.new(@another_user, @watched_user).execute
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
              @rel = Projects::Users::CreateRelationContext.new(@another_user, project, params).execute
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

        context "when user in project" do
          before do
            params = { user_ids: [@watched_user.id], project_access: Gitlab::Access::DEVELOPER }
            collect_mails_data do
              Projects::Users::CreateRelationContext.new(@another_user, project, params).execute
            end
          end

          context "when update user access to project" do
            before do
              collect_mails_data do
                Projects::Users::UpdateRelationContext.new(@another_user, project, @watched_user, { team_member: { project_access: Gitlab::Access::MASTER } }).execute
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
                Projects::Users::RemoveRelationContext.new(@another_user, project, @watched_user).execute
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
              Groups::Users::CreateRelationContext.new(@another_user, @group, params).execute
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
            Groups::Users::CreateRelationContext.new(@another_user, @group, params).execute
          end

          context "when update user access to group" do
            before do
              collect_mails_data do
                Groups::Users::UpdateRelationContext.new(@another_user, @group, @watched_user, {group_access: Gitlab::Access::MASTER }).execute
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
                Groups::Users::RemoveRelationContext.new(@another_user, @group, @watched_user).execute
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
              Teams::Users::CreateRelationContext.new(@another_user, @team, params).execute
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
            Teams::Users::CreateRelationContext.new(@another_user, @team, params).execute
          end

          context "we update access in team" do
            before do
              params = { team_access: Gitlab::Access::MASTER }
              collect_mails_data do
                Teams::Users::UpdateRelationContext.new(@another_user, @team, @watched_user, params).execute
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
                Teams::Users::RemoveRelationContext.new(@another_user, @team, @watched_user).execute
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
