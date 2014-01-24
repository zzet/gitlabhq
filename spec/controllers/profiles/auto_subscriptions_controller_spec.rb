require 'spec_helper'

describe Profiles::AutoSubscriptionsController do
  let(:user) { create(:user) }
  let(:auto_subscription_attrs) { attributes_for(:auto_subscription) }
  let(:auto_subscription) { create(:auto_subscription, user: user) }

  before do
    sign_in(user)
  end

  describe "#create" do
    it "should create auto subscription" do
      post :create, format: :json, auto_subscription: auto_subscription_attrs
      should respond_with :created
    end
  end

  describe "#destroy" do
    it "should destroy auto subscription" do
      delete :destroy, format: :json, id: auto_subscription.id

      should respond_with :no_content
    end
  end

end
