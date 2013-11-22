require 'spec_helper'

describe Teams::Projects::CreateRelationContext do
  before do
    ActiveRecord::Base.observers.enable(:user_observer) do
      @user = create :user
    end
    @team_opts = { name: "Team", description: "Team description" }
    @team = Teams::CreateContext.new(@user, @team_opts).execute
  end

  context 'non admin user' do
    context 'on own project' do
      before do
        project_opts = { name: "Gitlab" }
        @project = Projects::CreateContext.new(@user, project_opts).execute

        @project_team_rel_opts = { project_ids: "#{@project.id}" }
      end

      it "user should have" do
        allowed_project_ids = (@user.master_projects.pluck(:id) + @user.created_projects.pluck(:id) + @user.owned_projects.pluck(:id)).uniq
        allowed_project_ids.include?(@project.id).should be_true
      end

      it "user should assign own team" do
        Teams::Projects::CreateRelationContext.new(@user, @team, @project_team_rel_opts).execute

        @team.projects.include?(@project).should be_true
      end

      it "shoul assign not own but public team" do
        @another_user = create :user
        @public_team_opts = { name: "Public Team", description: "Team description", public: true }
        @public_team = Teams::CreateContext.new(@another_user, @public_team_opts).execute

        Teams::Projects::CreateRelationContext.new(@user, @public_team, @project_team_rel_opts).execute

        @public_team.projects.include?(@project).should be_true
        @project.team.owners.include?(@another_user).should be_true
      end
    end
  end
end
