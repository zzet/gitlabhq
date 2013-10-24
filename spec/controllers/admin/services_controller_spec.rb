require 'spec_helper'

describe Admin::ServicesController do
  let(:user)    { create(:admin) }

  before do
    sign_in user
  end

  describe "GET 'index'" do
    it "returns http success" do
      get :index
      response.should be_success
    end
  end

  Service.implement_services.map {|s| s.new }.each do |service|
    describe "GET 'new' with #{service.to_param} service" do
      it "returns http success" do
        get :new, key: Service::BuildFace.new.to_param
        response.should be_success
      end
    end

    describe "GET 'show' with #{service.to_param} service" do
      before do
        @new_service = create :"#{service.to_param}_service"
      end

      it "returns http success" do
        get :show, id: @new_service.to_param
        response.should be_success
      end
    end

    describe "POST 'create' with #{service.to_param} service" do
      it "returns http redirect" do
        attrs = attributes_for :"active_public_#{service.to_param}_service"
        attrs[:service_type] = service.to_param
        attrs[:active_state_event] = "activate"
        attrs[:public_state_event] = "publish"
        post :create, service: attrs
        response.should be_redirect
      end
    end

    describe "GET 'edit' with #{service.to_param} service" do
      before do
        @new_service = create :"#{service.to_param}_service"
      end

      it "returns http success" do
        get :edit, id: @new_service.to_param
        response.should be_success
      end
    end

    describe "PUT 'update' with #{service.to_param} service" do
      before do
        @new_service = create :"#{service.to_param}_service"
      end

      it "returns http redirect" do
        attrs = {}
        attrs[:active_state_event] = "activate"
        attrs[:public_state_event] = "publish"
        put :update, id: @new_service.to_param, service: attrs
        response.should be_redirect
      end
    end

    describe "DELETE 'destroy' with #{service.to_param} service" do
      before do
        @new_service = create :"#{service.to_param}_service"
      end

      it "returns http redirect" do
        delete :destroy, id: @new_service.to_param
        response.should be_redirect
      end
    end
  end
end
