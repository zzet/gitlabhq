require 'spec_helper'

describe Teams::Projects::RemoveRelationContext do
  before do
    @user = create :user
    @team_opts = { name: "Team", description: "Team description" }
    @team = Teams::CreateContext.new(@user, @team_opts).execute
  end

  context 'non admin user' do
    before do
      @user.admin = false
      @user.save
    end

    context 'assign team on own project' do
      before do
        project_opts = { name: "Gitlab" }
        @project = Projects::CreateContext.new(@user, project_opts).execute

        @project_team_rel_opts = { project_ids: "#{@project.id}" }
        Teams::Projects::CreateRelationContext.new(@user, @team, @project_team_rel_opts).execute
      end

      it "should resign own team on own project" do
        @team.projects.include?(@project).should be_true
        @project.team.owners.include?(@user).should be_true

        Teams::Projects::RemoveRelationContext.new(@user, @team, @project).execute

        @team.projects.include?(@project).should be_false
      end

      it "shoul assign not own but public team on own project" do
        @another_user = create :user
        @public_team_opts = { name: "Public Team", description: "Team description", public: true }
        @public_team = Teams::CreateContext.new(@another_user, @public_team_opts).execute

        Teams::Projects::CreateRelationContext.new(@user, @public_team, @project_team_rel_opts).execute

        Teams::Projects::RemoveRelationContext.new(@user, @public_team, @project).execute

        @public_team.projects.include?(@project).should be_false
        @project.team.owners.include?(@another_user).should be_false
      end
    end
  end
end
