require 'spec_helper'

describe PostReceive do

  context "as a resque worker" do
    it "reponds to #perform" do
      PostReceive.new.should respond_to(:perform)
    end
  end

  context "web hook" do
    let(:project) { create(:project_with_code) }
    let(:key) { create(:key, user: project.owner) }
    let(:key_id) { key.shell_id }

    it "fetches the correct project" do
      Project.should_receive(:find_with_namespace).with(project.path_with_namespace).and_return(project)
      PostReceive.new.perform(pwd(project), 'sha-old', 'sha-new', 'refs/heads/master', key_id)
    end

    it "does not run if the author is not in the project" do
      Key.stub(find_by_id: nil)

      project.should_not_receive(:execute_hooks)

      PostReceive.new.perform(pwd(project), 'sha-old', 'sha-new', 'refs/heads/master', key_id).should be_false
    end

    it "asks the project to trigger all hooks" do
      Project.stub(find_with_namespace: project)
      project.should_receive(:execute_hooks)
      project.should_receive(:execute_services)
      project.should_receive(:update_merge_requests)

      PostReceive.new.perform(pwd(project), 'sha-old', 'sha-new', 'refs/heads/master', key_id)
    end
  end

  context "push from" do
    let(:project) { create(:project_with_code) }
    let(:key) { create(:service_key) }
    let(:key_id) { key.shell_id }
    Service.implement_services.map {|s| s.new }.each do |service|
      describe "#{service.to_param} service" do
        before do
          @service = create :"active_public_#{service.to_param}_service"
          if @service.user_params.any?
            @service.service_keys << key
            @service_user = User.find_by_username(@service.user_params[:username])
            @service_user = User.create!(@service.user_params) if @service_user.blank?
            @service.create_service_user_relationship(user: @service_user)
          end
        end

        it "should receive data" do
          if @service.user_params.any?
            PostReceive.new.perform(pwd(project), 'sha-old', 'sha-new', 'refs/heads/master', key_id)
          end
        end
      end
    end
  end

  def pwd(project)
    File.join(Gitlab.config.gitlab_shell.repos_path, project.path_with_namespace)
  end
end
