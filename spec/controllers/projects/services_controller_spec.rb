require 'spec_helper'

describe Projects::ServicesController do
  let(:user)    { create(:user) }

  before do
    user.create_namespace!(path: user.username, name: user.username) unless user.namespace

    params = { project: attributes_for(:project_with_code) }
    @project = Projects::CreateContext.new(user, params[:project]).execute
    sign_in user
  end

  Service.implement_services.map {|s| s.new }.each do |service|
    describe "Manage #{service.to_param} service" do
      before do
        @service = create :"active_public_#{service.to_param}_service"
      end

      describe "GET 'index'" do
        it "returns http success" do
          get :index, project_id: @project.path_with_namespace
          response.should be_success
        end
      end

      describe "GET 'edit' pattern" do
        it "returns http success" do
          get :edit, project_id: @project.path_with_namespace, id: @service.to_param
          response.should be_success
        end
      end

      describe "GET 'edit' project service" do
        before do
          @project_service = Projects::Services::ImportContext.new(user, @project, @service, { service: { state_event: :enable }}).execute
        end

        it "returns http success" do
          get :edit, project_id: @project.path_with_namespace, id: @project_service.to_param
          response.should be_success
        end
      end

      describe "PUT 'update' with service pattern" do
        it "returns http redirect" do
          @service.children.should be_blank

          if service.to_param == "build_face"
            stub_request(:post, "http://build-face.undev.cc//hooks/gitlab").
              with(:headers => {'Content-Type'=>'application/json'}).
              to_return(:status => 200, :body => "", :headers => {})
          end

          attrs = { state_event: :enable }
          put :update, project_id: @project.path_with_namespace, id: @service.to_param, service: attrs
          response.should be_redirect

          @service.reload

          @service.children.should_not be_blank

          @project_service = @service.children.first
          @project_service.should be_enabled
        end
      end

      describe "PUT 'update' with project service" do
        before do
          @project_service = Projects::Services::ImportContext.new(user, @project, @service).execute
        end

        it "returns http redirect" do
          @project_service.should be_disabled

          if service.to_param == "build_face"
            stub_request(:post, "http://build-face.undev.cc//hooks/gitlab").
              with(:headers => {'Content-Type'=>'application/json'}).
              to_return(:status => 200, :body => "", :headers => {})
          end

          attrs = { state_event: :enable }
          put :update, project_id: @project.path_with_namespace, id: @project_service.to_param, service: attrs
          response.should be_redirect

          @project_service.reload
          @project_service.should be_enabled
        end
      end
    end
  end
end
