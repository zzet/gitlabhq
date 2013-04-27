require 'spec_helper'

describe UsersProjectObserver do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  subject { UsersProjectObserver.instance }
  before { subject.stub(notification: mock('NotificationService').as_null_object) }

  describe "#after_commit" do
    it "should called when UsersProject created" do
      subject.should_receive(:after_commit)
      create(:users_project)
    end

    it "should create new event" do
      OldEvent.should_receive(:create)

      create(:users_project)
    end
  end

  describe "#after_destroy" do
    before do
      @users_project = create :users_project
    end

    it "should called when UsersProject destroyed" do
      subject.should_receive(:after_destroy)
      @users_project.destroy
    end

    it "should create new event" do
      OldEvent.should_receive(:create)
      @users_project.destroy
    end
  end
end
