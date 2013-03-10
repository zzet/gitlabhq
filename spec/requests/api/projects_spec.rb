require 'spec_helper'

describe Gitlab::API do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:admin) { create(:admin) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:hook) { create(:project_hook, project: project, url: "http://example.com") }
  let!(:snippet) { create(:snippet, author: user, project: project, title: 'example') }
  let!(:users_project) { create(:users_project, user: user, project: project, project_access: UsersProject::MASTER) }
  let!(:users_project2) { create(:users_project, user: user3, project: project, project_access: UsersProject::DEVELOPER) }
  let(:key) { create(:key, project: project) }

  before { project.team << [user, :reporter] }

  describe "GET /projects" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/projects")
        response.status.should == 401
      end
    end

    context "when authenticated" do
      it "should return an array of projects" do
        get api("/projects", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['name'].should == project.name
        json_response.first['owner']['email'].should == user.email
      end
    end
  end

  describe "POST /projects" do
    context "maximum number of projects reached" do
      before do
        (1..user2.projects_limit).each do |project|
          post api("/projects", user2), name: "foo#{project}"
        end
      end

      it "should not create new project" do
        expect {
          post api("/projects", user2), name: 'foo'
        }.to change {Project.count}.by(0)
      end
    end

    it "should create new project without path" do
      expect { post api("/projects", user), name: 'foo' }.to change {Project.count}.by(1)
    end

    it "should not create new project without name" do
      expect { post api("/projects", user) }.to_not change {Project.count}
    end

    it "should return a 400 error if name not given" do
      post api("/projects", user)
      response.status.should == 400
    end

    it "should create last project before reaching project limit" do
      (1..user2.projects_limit-1).each { |p| post api("/projects", user2), name: "foo#{p}" }
      post api("/projects", user2), name: "foo"
      response.status.should == 201
    end

    it "should respond with 201 on success" do
      post api("/projects", user), name: 'foo'
      response.status.should == 201
    end

    it "should respond with 400 if name is not given" do
      post api("/projects", user)
      response.status.should == 400
    end

    it "should return a 403 error if project limit reached" do
      (1..user.projects_limit).each do |p|
        post api("/projects", user), name: "foo#{p}"
      end
      post api("/projects", user), name: 'bar'
      response.status.should == 403
    end

    it "should assign attributes to project" do
      project = attributes_for(:project, {
        description: Faker::Lorem.sentence,
        default_branch: 'stable',
        issues_enabled: false,
        wall_enabled: false,
        merge_requests_enabled: false,
        wiki_enabled: false
      })

      post api("/projects", user), project

      project.each_pair do |k,v|
        next if k == :path
        json_response[k.to_s].should == v
      end
    end
  end

  describe "POST /projects/user/:id" do
    before { admin }

    it "should create new project without path" do
      expect { post api("/projects/user/#{user.id}", admin), name: 'foo' }.to change {Project.count}.by(1)
    end

    it "should not create new project without name" do
      expect { post api("/projects/user/#{user.id}", admin) }.to_not change {Project.count}
    end

    it "should respond with 201 on success" do
      post api("/projects/user/#{user.id}", admin), name: 'foo'
      response.status.should == 201
    end

    it "should respond with 404 on failure" do
      post api("/projects/user/#{user.id}", admin)
      response.status.should == 404
    end

    it "should assign attributes to project" do
      project = attributes_for(:project, {
        description: Faker::Lorem.sentence,
        default_branch: 'stable',
        issues_enabled: false,
        wall_enabled: false,
        merge_requests_enabled: false,
        wiki_enabled: false
      })

      post api("/projects/user/#{user.id}", admin), project

      project.each_pair do |k,v|
        next if k == :path
        json_response[k.to_s].should == v
      end
    end
  end

  describe "GET /projects/:id" do
    it "should return a project by id" do
      get api("/projects/#{project.id}", user)
      response.status.should == 200
      json_response['name'].should == project.name
      json_response['owner']['email'].should == user.email
    end

    it "should return a project by path name" do
      get api("/projects/#{project.id}", user)
      response.status.should == 200
      json_response['name'].should == project.name
    end

    it "should return a 404 error if not found" do
      get api("/projects/42", user)
      response.status.should == 404
      json_response['message'].should == '404 Not Found'
    end

    it "should return a 404 error if user is not a member" do
      other_user = create(:user)
      get api("/projects/#{project.id}", other_user)
      response.status.should == 404
    end
  end

  describe "GET /projects/:id/repository/branches" do
    it "should return an array of project branches" do
      get api("/projects/#{project.id}/repository/branches", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == project.repo.heads.sort_by(&:name).first.name
    end
  end

  describe "GET /projects/:id/repository/branches/:branch" do
    it "should return the branch information for a single branch" do
      get api("/projects/#{project.id}/repository/branches/new_design", user)
      response.status.should == 200

      json_response['name'].should == 'new_design'
      json_response['commit']['id'].should == '621491c677087aa243f165eab467bfdfbee00be1'
      json_response['protected'].should == false
    end

    it "should return a 404 error if branch is not available" do
      get api("/projects/#{project.id}/repository/branches/unknown", user)
      response.status.should == 404
    end
  end

  describe "PUT /projects/:id/repository/branches/:branch/protect" do
    it "should protect a single branch" do
      put api("/projects/#{project.id}/repository/branches/new_design/protect", user)
      response.status.should == 200

      json_response['name'].should == 'new_design'
      json_response['commit']['id'].should == '621491c677087aa243f165eab467bfdfbee00be1'
      json_response['protected'].should == true
    end

    it "should return a 404 error if branch not found" do
      put api("/projects/#{project.id}/repository/branches/unknown/protect", user)
      response.status.should == 404
    end

    it "should return success when protect branch again" do
      put api("/projects/#{project.id}/repository/branches/new_design/protect", user)
      put api("/projects/#{project.id}/repository/branches/new_design/protect", user)
      response.status.should == 200
    end
  end

  describe "PUT /projects/:id/repository/branches/:branch/unprotect" do
    it "should unprotect a single branch" do
      put api("/projects/#{project.id}/repository/branches/new_design/unprotect", user)
      response.status.should == 200

      json_response['name'].should == 'new_design'
      json_response['commit']['id'].should == '621491c677087aa243f165eab467bfdfbee00be1'
      json_response['protected'].should == false
    end

    it "should return success when unprotect branch" do
      put api("/projects/#{project.id}/repository/branches/unknown/unprotect", user)
      response.status.should == 404
    end

    it "should return success when unprotect branch again" do
      put api("/projects/#{project.id}/repository/branches/new_design/unprotect", user)
      put api("/projects/#{project.id}/repository/branches/new_design/unprotect", user)
      response.status.should == 200
    end
  end

  describe "GET /projects/:id/members" do
    it "should return project team members" do
      get api("/projects/#{project.id}/members", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.count.should == 2
      json_response.first['email'].should == user.email
    end

    it "finds team members with query string" do
      get api("/projects/#{project.id}/members", user), query: user.username
      response.status.should == 200
      json_response.should be_an Array
      json_response.count.should == 1
      json_response.first['email'].should == user.email
    end

    it "should return a 404 error if id not found" do
      get api("/projects/9999/members", user)
      response.status.should == 404
    end
  end

  describe "GET /projects/:id/members/:user_id" do
    it "should return project team member" do
      get api("/projects/#{project.id}/members/#{user.id}", user)
      response.status.should == 200
      json_response['email'].should == user.email
      json_response['access_level'].should == UsersProject::MASTER
    end

    it "should return a 404 error if user id not found" do
      get api("/projects/#{project.id}/members/1234", user)
      response.status.should == 404
    end
  end

  describe "POST /projects/:id/members" do
    it "should add user to project team" do
      expect {
        post api("/projects/#{project.id}/members", user), user_id: user2.id,
          access_level: UsersProject::DEVELOPER
      }.to change { UsersProject.count }.by(1)

      response.status.should == 201
      json_response['email'].should == user2.email
      json_response['access_level'].should == UsersProject::DEVELOPER
    end

    it "should return a 201 status if user is already project member" do
      post api("/projects/#{project.id}/members", user), user_id: user2.id,
        access_level: UsersProject::DEVELOPER
      expect {
        post api("/projects/#{project.id}/members", user), user_id: user2.id,
          access_level: UsersProject::DEVELOPER
      }.not_to change { UsersProject.count }.by(1)

      response.status.should == 201
      json_response['email'].should == user2.email
      json_response['access_level'].should == UsersProject::DEVELOPER
    end

    it "should return a 400 error when user id is not given" do
      post api("/projects/#{project.id}/members", user), access_level: UsersProject::MASTER
      response.status.should == 400
    end

    it "should return a 400 error when access level is not given" do
      post api("/projects/#{project.id}/members", user), user_id: user2.id
      response.status.should == 400
    end

    it "should return a 422 error when access level is not known" do
      post api("/projects/#{project.id}/members", user), user_id: user2.id, access_level: 1234
      response.status.should == 422
    end
  end

  describe "PUT /projects/:id/members/:user_id" do
    it "should update project team member" do
      put api("/projects/#{project.id}/members/#{user3.id}", user), access_level: UsersProject::MASTER
      response.status.should == 200
      json_response['email'].should == user3.email
      json_response['access_level'].should == UsersProject::MASTER
    end

    it "should return a 404 error if user_id is not found" do
      put api("/projects/#{project.id}/members/1234", user), access_level: UsersProject::MASTER
      response.status.should == 404
    end

    it "should return a 400 error when access level is not given" do
      put api("/projects/#{project.id}/members/#{user3.id}", user)
      response.status.should == 400
    end

    it "should return a 422 error when access level is not known" do
      put api("/projects/#{project.id}/members/#{user3.id}", user), access_level: 123
      response.status.should == 422
    end
  end

  describe "DELETE /projects/:id/members/:user_id" do
    it "should remove user from project team" do
      expect {
        delete api("/projects/#{project.id}/members/#{user3.id}", user)
      }.to change { UsersProject.count }.by(-1)
    end

    it "should return 200 if team member is not part of a project" do
      delete api("/projects/#{project.id}/members/#{user3.id}", user)
      expect {
        delete api("/projects/#{project.id}/members/#{user3.id}", user)
      }.to_not change { UsersProject.count }.by(1)
    end

    it "should return 200 if team member already removed" do
      delete api("/projects/#{project.id}/members/#{user3.id}", user)
      delete api("/projects/#{project.id}/members/#{user3.id}", user)
      response.status.should == 200
    end
  end

  describe "DELETE /projects/:id/members/:user_id" do
    it "should return 200 OK when the user was not member" do
      expect {
        delete api("/projects/#{project.id}/members/1000000", user)
      }.to change { UsersProject.count }.by(0)
      response.status.should == 200
      json_response['message'].should == "Access revoked"
      json_response['id'].should == 1000000
    end
  end

  describe "GET /projects/:id/hooks" do
    context "authorized user" do
      it "should return project hooks" do
        get api("/projects/#{project.id}/hooks", user)
        response.status.should == 200

        json_response.should be_an Array
        json_response.count.should == 1
        json_response.first['url'].should == "http://example.com"
      end
    end

    context "unauthorized user" do
      it "should not access project hooks" do
        get api("/projects/#{project.id}/hooks", user3)
        response.status.should == 403
      end
    end
  end

  describe "GET /projects/:id/hooks/:hook_id" do
    context "authorized user" do
      it "should return a project hook" do
        get api("/projects/#{project.id}/hooks/#{hook.id}", user)
        response.status.should == 200
        json_response['url'].should == hook.url
      end

      it "should return a 404 error if hook id is not available" do
        get api("/projects/#{project.id}/hooks/1234", user)
        response.status.should == 404
      end
    end

    context "unauthorized user" do
      it "should not access an existing hook" do
        get api("/projects/#{project.id}/hooks/#{hook.id}", user3)
        response.status.should == 403
      end
    end

    it "should return a 404 error if hook id is not available" do
      get api("/projects/#{project.id}/hooks/1234", user)
      response.status.should == 404
    end
  end

  describe "POST /projects/:id/hooks" do
    it "should add hook to project" do
      expect {
        post api("/projects/#{project.id}/hooks", user),
          url: "http://example.com"
      }.to change {project.hooks.count}.by(1)
      response.status.should == 201
    end

    it "should return a 400 error if url not given" do
      post api("/projects/#{project.id}/hooks", user)
      response.status.should == 400
    end

    it "should return a 422 error if url not valid" do
      post api("/projects/#{project.id}/hooks", user), "url" => "ftp://example.com"
      response.status.should == 422
    end
  end

  describe "PUT /projects/:id/hooks/:hook_id" do
    it "should update an existing project hook" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user),
        url: 'http://example.org'
      response.status.should == 200
      json_response['url'].should == 'http://example.org'
    end

    it "should return 404 error if hook id not found" do
      put api("/projects/#{project.id}/hooks/1234", user), url: 'http://example.org'
      response.status.should == 404
    end

    it "should return 400 error if url is not given" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user)
      response.status.should == 400
    end

    it "should return a 422 error if url is not valid" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user), url: 'ftp://example.com'
      response.status.should == 422
    end
  end

  describe "DELETE /projects/:id/hooks" do
    it "should delete hook from project" do
      expect {
        delete api("/projects/#{project.id}/hooks", user), hook_id: hook.id
      }.to change {project.hooks.count}.by(-1)
      response.status.should == 200
    end

    it "should return success when deleting hook" do
      delete api("/projects/#{project.id}/hooks", user), hook_id: hook.id
      response.status.should == 200
    end

    it "should return success when deleting non existent hook" do
      delete api("/projects/#{project.id}/hooks", user), hook_id: 42
      response.status.should == 200
    end

    it "should return a 400 error if hook id not given" do
      delete api("/projects/#{project.id}/hooks", user)
      response.status.should == 400
    end
  end

  describe "GET /projects/:id/repository/tags" do
    it "should return an array of project tags" do
      get api("/projects/#{project.id}/repository/tags", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == project.repo.tags.sort_by(&:name).reverse.first.name
    end
  end

  describe "GET /projects/:id/repository/commits" do
    context "authorized user" do
      before { project.team << [user2, :reporter] }

      it "should return project commits" do
        get api("/projects/#{project.id}/repository/commits", user)
        response.status.should == 200

        json_response.should be_an Array
        json_response.first['id'].should == project.repository.commit.id
      end
    end

    context "unauthorized user" do
      it "should not return project commits" do
        get api("/projects/#{project.id}/repository/commits")
        response.status.should == 401
      end
    end
  end

  describe "GET /projects/:id/snippets" do
    it "should return an array of project snippets" do
      get api("/projects/#{project.id}/snippets", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['title'].should == snippet.title
    end
  end

  describe "GET /projects/:id/snippets/:snippet_id" do
    it "should return a project snippet" do
      get api("/projects/#{project.id}/snippets/#{snippet.id}", user)
      response.status.should == 200
      json_response['title'].should == snippet.title
    end

    it "should return a 404 error if snippet id not found" do
      get api("/projects/#{project.id}/snippets/1234", user)
      response.status.should == 404
    end
  end

  describe "POST /projects/:id/snippets" do
    it "should create a new project snippet" do
      post api("/projects/#{project.id}/snippets", user),
        title: 'api test', file_name: 'sample.rb', code: 'test'
      response.status.should == 201
      json_response['title'].should == 'api test'
    end

    it "should return a 400 error if title is not given" do
      post api("/projects/#{project.id}/snippets", user),
        file_name: 'sample.rb', code: 'test'
      response.status.should == 400
    end

    it "should return a 400 error if file_name not given" do
      post api("/projects/#{project.id}/snippets", user),
        title: 'api test', code: 'test'
      response.status.should == 400
    end

    it "should return a 400 error if code not given" do
      post api("/projects/#{project.id}/snippets", user),
        title: 'api test', file_name: 'sample.rb'
      response.status.should == 400
    end
  end

  describe "PUT /projects/:id/snippets/:shippet_id" do
    it "should update an existing project snippet" do
      put api("/projects/#{project.id}/snippets/#{snippet.id}", user),
        code: 'updated code'
      response.status.should == 200
      json_response['title'].should == 'example'
      snippet.reload.content.should == 'updated code'
    end

    it "should update an existing project snippet with new title" do
      put api("/projects/#{project.id}/snippets/#{snippet.id}", user),
        title: 'other api test'
      response.status.should == 200
      json_response['title'].should == 'other api test'
    end
  end

  describe "DELETE /projects/:id/snippets/:snippet_id" do
    it "should delete existing project snippet" do
      expect {
        delete api("/projects/#{project.id}/snippets/#{snippet.id}", user)
      }.to change { Snippet.count }.by(-1)
      response.status.should == 200
    end

    it "should return success when deleting unknown snippet id" do
      delete api("/projects/#{project.id}/snippets/1234", user)
      response.status.should == 200
    end
  end

  describe "GET /projects/:id/snippets/:snippet_id/raw" do
    it "should get a raw project snippet" do
      get api("/projects/#{project.id}/snippets/#{snippet.id}/raw", user)
      response.status.should == 200
    end

    it "should return a 404 error if raw project snippet not found" do
      get api("/projects/#{project.id}/snippets/5555/raw", user)
      response.status.should == 404
    end
  end

  describe "GET /projects/:id/repository/commits/:sha/blob" do
    it "should get the raw file contents" do
      get api("/projects/#{project.id}/repository/commits/master/blob?filepath=README.md", user)
      response.status.should == 200
    end

    it "should return 404 for invalid branch_name" do
      get api("/projects/#{project.id}/repository/commits/invalid_branch_name/blob?filepath=README.md", user)
      response.status.should == 404
    end

    it "should return 404 for invalid file" do
      get api("/projects/#{project.id}/repository/commits/master/blob?filepath=README.invalid", user)
      response.status.should == 404
    end

    it "should return a 400 error if filepath is missing" do
      get api("/projects/#{project.id}/repository/commits/master/blob", user)
      response.status.should == 400
    end
  end

  describe "GET /projects/:id/keys" do
    it "should return array of ssh keys" do
      project.deploy_keys << key
      project.save
      get api("/projects/#{project.id}/keys", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['title'].should == key.title
    end
  end

  describe "GET /projects/:id/keys/:key_id" do
    it "should return a single key" do
      project.deploy_keys << key
      project.save
      get api("/projects/#{project.id}/keys/#{key.id}", user)
      response.status.should == 200
      json_response['title'].should == key.title
    end

    it "should return 404 Not Found with invalid ID" do
      get api("/projects/#{project.id}/keys/404", user)
      response.status.should == 404
    end
  end

  describe "POST /projects/:id/keys" do
    it "should not create an invalid ssh key" do
      post api("/projects/#{project.id}/keys", user), { title: "invalid key" }
      response.status.should == 404
    end

    it "should create new ssh key" do
      key_attrs = attributes_for :key
      expect {
        post api("/projects/#{project.id}/keys", user), key_attrs
      }.to change{ project.deploy_keys.count }.by(1)
    end
  end

  describe "DELETE /projects/:id/keys/:key_id" do
    it "should delete existing key" do
      project.deploy_keys << key
      project.save
      expect {
        delete api("/projects/#{project.id}/keys/#{key.id}", user)
      }.to change{ project.deploy_keys.count }.by(-1)
    end

    it "should return 404 Not Found with invalid ID" do
      delete api("/projects/#{project.id}/keys/404", user)
      response.status.should == 404
    end
  end
end
