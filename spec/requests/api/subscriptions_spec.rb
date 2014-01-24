require 'spec_helper'

describe API::API do
  include ApiHelpers
  before(:each) { ActiveRecord::Base.observers.enable(:user_observer) }
  after(:each) { ActiveRecord::Base.observers.disable(:user_observer) }

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace ) }
  let(:group) { create(:group, owner: user) }
  let(:second_project) { create(:project, namespace: user.namespace ) }
  before { project.team << [user, :reporter] }

  describe "subscriptions api" do

    context "#index" do
      before do
        Gitlab::Event::Subscription.subscribe(user, project)
      end

      it "should get subscription" do
        get api("/subscriptions/targets/", user), type: 'Project', id: project.id
        response.status.should == 200
        body = JSON.parse(response.body)

        expect(body["count"]).to eq(1)
        expect(body["targets"][0]["options"]["push"]).to be_true
      end
    end

    context "#create" do
      it "should create subscription" do
        post api("/subscriptions/", user), target: {type: 'project', id: project.id}
        response.status.should == 201
        options = user.personal_subscriptions.find_by(target_id: project.id, target_type: 'Project').options

        expect(options).to eq(Project.watched_sources.map(&:to_s))
      end
    end

    context "#delete" do
      before do
        Gitlab::Event::Subscription.subscribe(user, project)
      end

      it "should destroy subscription" do
        delete api("/subscriptions/#{project.class.name.underscore}/#{project.id}", user)
        response.status.should == 204

        subscription = user.personal_subscriptions.find_by(target_id: project.id, target_type: 'Project')
        expect(subscription).to be_nil
      end
    end

    context "#options_update" do
      before do
        @subscription = Gitlab::Event::Subscription.subscribe(user, project)
        @second_subscription = Gitlab::Event::Subscription.subscribe(user, second_project)
        @option = project.class.watched_sources.first
      end

      it "should bulk update subscriptions" do
        patch api("/subscriptions/options", user), { options: [@option],
                                                     type: project.class,
                                                     targets: [project.id, second_project.id]}
        response.status.should == 204

        @subscription.reload
        @second_subscription.reload

        expect(@subscription.options.map(&:to_sym)).to eq([@option])
        expect(@second_subscription.options.map(&:to_sym)).to eq([@option])
      end

      it "should update all subscriptions" do
        patch api("/subscriptions/options", user), { options: [@option],
                                                     type: project.class,
                                                     targets: 'all'}
        response.status.should == 204

        @subscription.reload
        @second_subscription.reload

        expect(@subscription.options.map(&:to_sym)).to eq([@option])
        expect(@second_subscription.options.map(&:to_sym)).to eq([@option])
      end
    end

    context "#to_all" do
      before do
        project
        second_project
      end

      it "should subscribe to all available projects" do
        post api("/subscriptions/to_all", user), {subscription_type: 'project'}
        response.status.should == 200

        expect(user.personal_subscriptions.map(&:target)).to eq([project, second_project])
      end
    end

    context "#from_all" do
      before do
        project
        second_project

        @subscription = Gitlab::Event::Subscription.subscribe(user, project)
        @second_subscription = Gitlab::Event::Subscription.subscribe(user, second_project)
      end

      it "should unsubscribe from all available projects" do
        post api("/subscriptions/from_all", user), {subscription_type: 'project'}
        response.status.should == 200

        user.reload

        expect(user.personal_subscriptions).to be_empty
      end
    end

    context "#create adjacent" do
      it "should create adjacent subscription" do
        post api("/subscriptions/adjacent", user), {
          namespace_id: group.id,
          namespace_type: group.class.to_s,
          target: 'project',
        }
        response.status.should == 201

        adjacent_targets = user.auto_subscriptions.adjacent(group.class.name, group.id).
            pluck(:target)

        expect(adjacent_targets).to eq(%w(project))
      end
    end

    context "#delete adjacent" do
      before do
        @as = create(:adjacent_auto_subscription, user: user,
                     namespace_id: group.id, namespace_type: group.class.name)
      end

      it "should delete adjacent subscription" do
        delete api("/subscriptions/adjacent", user), {
            namespace_id: group.id,
            namespace_type: group.class.to_s,
            target: 'project',
        }
        response.status.should == 204

        adjacent_targets = Event::AutoSubscription.adjacent(group.class.name, group.id).
            pluck(:target)

        expect(adjacent_targets).to eq([])
      end
    end

  end
end
