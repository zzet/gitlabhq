require 'spec_helper'

describe Admin::Services::KeysController do
  let(:user)    { create(:admin) }

  before do
    sign_in user
  end

  Service.descendants.map {|s| s.new }.each do |service|
    describe "Manage keys for #{service.to_param} service" do
      before do
        @service = create :"active_public_#{service.to_param}_service"
      end

      describe "GET 'index'" do
        it "returns http success" do
          get :index, service_id: @service.id
          response.should be_success
        end
      end

      describe "GET 'edit'" do
        before do
          @key = create :service_key
          @service.service_keys << @key
        end

        it "returns http success" do
          get :edit, service_id: @service.id, id: @key.id
          response.should be_success
        end
      end

      describe "PUT 'disable'" do
        before do
          @key = create :service_key
        end

        it "returns http redirect" do
          put :disable, service_id: @service.id, id: @key.id
          response.should be_redirect
        end
      end

      describe "PUT 'enable'" do
        before do
          @key = create :service_key
        end

        it "returns http redirect" do
          put :enable, service_id: @service.id, id: @key.id
          response.should be_redirect
        end
      end

      describe "GET 'new'" do
        it "returns http success" do
          get :new, service_id: @service.id
          response.should be_success
        end
      end

      describe "POST 'create'" do
        it "returns http success" do
          attrs = attributes_for :service_key
          post :create, service_id: @service.id, service_key: attrs
          response.should be_redirect
        end
      end

      describe "DELETE 'destroy'" do
        before do
          @key = create :service_key
          @service.service_keys << @key
        end

        it "returns http redirect" do
          delete :destroy, service_id: @service.id, id: @key.id
          response.should be_redirect
        end
      end

      describe "GET 'show'" do
        before do
          @key = create :service_key
          @service.service_keys << @key
        end

        it "returns http success" do
          get :show, service_id: @service.id, id: @key.id
          response.should be_success
        end
      end
    end
  end
end
