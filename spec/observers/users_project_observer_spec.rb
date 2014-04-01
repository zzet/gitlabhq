require 'spec_helper'

describe UsersProjectObserver do
  before(:each) { enable_observers }
  after(:each) { disable_observers }

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  subject { UsersProjectObserver.instance }
  before { subject.stub(notification: double('NotificationService').as_null_object) }

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

  describe "#after_create" do
    it "should send email to user" do
      subject.should_receive(:notification)
      OldEvent.stub(create: true)

      create(:users_project)
    end

    it "should create new event" do
      OldEvent.should_receive(:create)

      create(:users_project)
    end
  end
end
