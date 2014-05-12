require 'spec_helper'

describe Projects::TeamMembersController do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:third_user) { create(:user) }

  before do
    user.create_namespace!(path: user.username, name: user.username) unless user.namespace

    params = { project: attributes_for(:project) }
    @project = ProjectsService.new(user, params[:project]).create
    sign_in user
  end

  describe "#batch_delete" do
    before do
      @project.team << [[second_user, third_user], Gitlab::Access::GUEST]
      @users_projects = @project.users_projects
    end

    it 'should work' do
      delete :batch_delete, project_id: @project,
             ids: @users_projects[0..1], format: 'js'

      expect(response.status).to eq(200)
    end
  end
end
