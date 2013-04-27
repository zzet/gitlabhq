require 'spec_helper'

describe IssueObserver do
  let(:some_user)      { create :user }
  let(:assignee)       { create :user }
  let(:author)         { create :user }
  let(:mock_issue)     { double(:issue, id: 42, assignee: assignee, author: author) }
  let(:assigned_issue)   { create(:issue, assignee: assignee, author: author) }
  let(:unassigned_issue) { create(:issue, author: author) }
  let(:closed_assigned_issue)   { create(:closed_issue, assignee: assignee, author: author) }
  let(:closed_unassigned_issue) { create(:closed_issue, author: author) }


  before(:each) { subject.stub(:current_user).and_return(some_user) }

  subject { IssueObserver.instance }

  describe '#after_create' do

    it 'is called when an issue is created' do
      subject.should_receive(:after_create)

      Issue.observers.enable :issue_observer do
        create(:issue, project: create(:project))
      end
    end
  end

  context '#after_close' do
    context 'a status "closed"' do
      it 'note is created if the issue is being closed' do
        Note.should_receive(:create_status_change_note).with(assigned_issue, some_user, 'closed')

        assigned_issue.close
      end
    end

    context 'a status "reopened"' do
      it 'note is created if the issue is being reopened' do
        Note.should_receive(:create_status_change_note).with(closed_assigned_issue, some_user, 'reopened')

        closed_assigned_issue.reopen
      end
    end
  end

  context '#after_update' do
    before(:each) do
      mock_issue.stub(:is_being_reassigned?).and_return(false)
    end

    it 'is called when an issue is changed' do
      changed = create(:issue, project: create(:project))
      subject.should_receive(:after_update)

      Issue.observers.enable :issue_observer do
        changed.description = 'I changed'
        changed.save
      end
    end
  end
end
