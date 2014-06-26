require 'spec_helper'

describe IssuesService do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:issue) { create(:issue, assignee: user2) }

  describe :create do
    context "valid params" do
      before do
        project.team << [user, :master]
        opts = {
          title: 'Awesome issue',
          description: 'please fix'
        }

        @issue = ProjectsService.new(user, project, issue: opts).issue.create
      end

      it { @issue.should be_valid }
      it { @issue.title.should == 'Awesome issue' }
    end
  end

  context "with exist issue" do
    before do
      project.team << [user, :master]
      project.team << [user2, :developer]
    end

    describe :close do
      context "valid params" do
        before do
          @issue = ProjectsService.new(user, project).issue(issue).close
        end

        it { @issue.should be_valid }
        it { @issue.should be_closed }

        it 'should create system note about issue reassign' do
          note = @issue.notes.last
          note.note.should include "Status changed to closed"
        end
      end
    end

    describe :update do
      context "valid params" do
        before do
          opts = {
            title: 'New title',
            description: 'Also please fix',
            assignee_id: user2.id,
            state_event: 'close'
          }

          @issue = ProjectsService.new(user, project, opts).issue(issue).update
        end

        it { @issue.should be_valid }
        it { @issue.title.should == 'New title' }
        it { @issue.assignee.should == user2 }
        it { @issue.should be_closed }
      end
    end
  end
end
