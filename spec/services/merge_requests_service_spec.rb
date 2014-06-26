require 'spec_helper'

describe "MergeRequestsService" do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe :create do
    context "valid params" do
      before do
        project.team << [user, :master]
        opts = {
          title: 'Awesome merge_request',
          description: 'please fix',
          source_branch: 'stable',
          target_branch: 'master'
        }

        @merge_request = ProjectsService.new(user, project, opts).merge_request.create
      end

      it { @merge_request.should be_valid }
      it { @merge_request.title.should == 'Awesome merge_request' }
    end
  end

  context "exist merge request" do

    before do
      @user2 = create(:user)
      @merge_request = create(:merge_request, :simple)
      project.team << [user, :master]
      project.team << [@user2, :developer]
    end

    describe "update" do
      before do
        opts = {
          merge_request: {
            title: 'New title',
            description: 'Also please fix',
            assignee_id: @user2.id,
            state_event: 'close'
          }
        }

        @merge_request = ProjectsService.new(user, project, opts).merge_request(@merge_request).update
      end

      it { @merge_request.should be_valid }
      it { @merge_request.title.should == 'New title' }
      it { @merge_request.assignee.should == @user2 }
      it { @merge_request.should be_closed }
    end

    describe :close do
      context "valid params" do
        before do
          @merge_request = ProjectsService.new(user, project, {}).merge_request(@merge_request).close
        end

        it { @merge_request.should be_valid }
        it { @merge_request.should be_closed }
      end
    end
  end

end
