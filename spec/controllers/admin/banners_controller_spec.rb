require 'spec_helper'

describe Admin::BannersController do
  let(:user)    { create(:user, admin: true) }
  let(:banner)  { create(:banner) }

  before do
    sign_in user
  end

  describe "GET 'index'" do
    it "returns http success" do
      get :index
      response.should be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get :new
      response.should be_success
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get :edit, id: banner.id
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      attrs = attributes_for :banner
      post :create, banner: attrs
      response.should be_redirect
      @banner = Banner.last
      @banner.should be_present
      @banner.title.should == attrs[:title]
    end
  end

  describe "DELETE 'destroy'" do
    it "returns http success" do
      delete :destroy, id: banner.id
      response.should be_redirect
      @banner = Banner.find_by_id(banner.id)
      @banner.should be_nil
    end
  end

  describe "PUT 'update'" do
    it "returns http success" do
      attrs = attributes_for :banner
      put :update, id: banner.id, banner: attrs
      response.should be_redirect
      banner.reload
      banner.title.should == attrs[:title]
    end
  end

end
