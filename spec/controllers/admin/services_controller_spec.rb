require 'spec_helper'

describe Admin::ServicesController do

  describe "GET 'index'" do
    it "returns http success" do
      get :index
      response.should be_success
    end
  end

  Service.descendants.map {|s| s.new }.each do |service|
    describe "GET 'new' with #{service.to_param} service" do
      it "returns http success" do
        get :new, key: Service::BuildFace.new.to_param
        response.should be_success
      end
    end

    describe "GET 'show' with #{service.to_param} service" do
      it "returns http success" do
        get :show
        response.should be_success
      end
    end

    describe "POST 'create' with #{service.to_param} service" do
      it "returns http success" do
        post :create
        response.should be_redirect
      end
    end

    describe "GET 'edit' with #{service.to_param} service" do
      it "returns http success" do
        get :edit
        response.should be_success
      end
    end

    describe "PUT 'update' with #{service.to_param} service" do
      it "returns http success" do
        get :update
        response.should be_redirect
      end
    end

    describe "DELETE 'destroy' with #{service.to_param} service" do
      it "returns http success" do
        get :destroy
        response.should be_redirect
      end
    end
  end

end
