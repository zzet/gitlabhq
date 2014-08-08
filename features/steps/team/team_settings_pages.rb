class Spinach::Features::TeamSettingsPages < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include Select2Helper

  step 'I submit form with updated team info' do
    fill_in 'team_name', with: 'Open Source team'
    fill_in 'team_description', with: 'Open Source team description'
    click_button 'Save team'
  end

  step 'I should be redirected to team settings page' do
    current_path.should == edit_team_path(current_team)
  end

  step 'I should be redirected to team members settings page' do
    current_path.should == team_members_path(current_team)
  end

  step 'I should see updated team' do
    within ".navbar-gitlab" do
      page.should have_content "team: Open Source team"
    end
  end

  step 'I have team' do
    @team = create(:team, creator: current_user)
  end

  step 'I have user \'Sam\'' do
    @user = create :user, name: 'Sam', username: 'sam'
  end

  step 'I have user \'John\'' do
    @user = create :user, name: 'John', username: 'john'
  end

  step 'I have group \'Undev\'' do
    @group = create :group, name: "Undev", owner: current_user
  end

  step 'I have group \'Gitlab\'' do
    @group = create :group, name: "Gitlab", owner: current_user
  end

  step 'I have project \'Undev\'' do
    @project = create :project, name: "Undev", creator: current_user
  end

  step 'I have project \'Gitlab\'' do
    @project = create :project, name: "Gitlab", creator: current_user
  end

  step 'I select user \'Sam\' with role \'Master\'' do
    user = User.find_by(name: "Sam")
    within "#new_team_user_relationship" do
      select2(user.id, from: "#user_ids", multiple: true)
      select "Master", from: "team_access"
    end
    click_button "Add users into team"
  end

  step 'I shoud remove user \'Sam\' from team' do
    user = User.find_by(name: "Sam")
    rel = user.team_user_relationships.find_by(team_id: current_team.id)
    within "#team_user_relationship_#{rel.id}" do
      page.find("a.btn-remove").click
    end
  end

  step 'I should see \'Sam\' in team members list with role \'Master\'' do
    within ".team_members_list" do
      page.should have_content "Sam"
      page.should have_content "sam"
      page.should have_content "Master"
    end
  end

  step 'I should not see \'Sam\' in team members list' do
    within ".team_members_list" do
      all(".team_user_relationship").count.should == 1
    end
  end

  step 'I update user \'Sam\' to with \'Develop\' role' do
    user = User.find_by(name: "Sam")
    rel = user.team_user_relationships.find_by(team_id: current_team.id)
    within "#team_user_relationship_#{rel.id}" do
      page.find("a.js-toggle-button").click

      within ".js-toggle-content" do
        select "Develop", from: "team_user_relationship_team_access"
        click_button "Save"
      end
    end
  end

  step 'I should see \'Sam\' in team members list with role \'Develop\'' do
    within ".team_members_list" do
      page.should have_content "Sam"
      page.should have_content "sam"
      page.should have_content "Developer"
    end
  end

  step 'I select users \'Sam\' and \'John\' with role \'Master\'' do
    user1 = User.find_by(name: "Sam")
    user2 = User.find_by(name: "John")
    within "#new_team_user_relationship" do
      select2("#{user1.id},#{user2.id}", from: "#user_ids", multiple: true)
      select "Master", from: "team_access"
    end
    click_button "Add users into team"
  end

  step 'I should see \'Sam\' and \'John\' in team members list with role \'Master\'' do
    within ".team_members_list" do
      page.should have_content "Sam"
      page.should have_content "Sam"
      page.should have_content "John"
      page.should have_content "john"
    end
  end

  step 'I select project \'Undev\'' do
    project = Project.find_by(name: "Undev")
    within "#new_team_project_relationship" do
      select2(project.id, from: "#project_ids", multiple: true)
    end
    click_button "Assign team on selected projects"
  end

  step 'I select group \'Undev\'' do
    group = Group.find_by(name: "Undev")
    within "#new_team_group_relationship" do
      select2(group.id, from: "#group_ids", multiple: true)
    end
    click_button "Assign team on selected groups"
  end

  step 'I select groups \'Undev\' and \'Gitlab\'' do
    group1 = Group.find_by(name: "Undev")
    group2 = Group.find_by(name: "Gitlab")
    within "#new_team_group_relationship" do
      select2("#{group2.id},#{group1.id}", from: "#group_ids", multiple: true)
      sleep 2
    end
    click_button "Assign team on selected groups"
  end

  step 'I should be redirected to team groups settings page' do
    current_path.should == team_groups_path(current_team)
  end

  step 'I should be redirected to team projects settings page' do
    current_path.should == team_projects_path(current_team)
  end

  step 'I should see \'Undev\' in team groups list' do
    within ".team_groups_list" do
      page.should have_content "Undev"
    end
  end

  step 'I should see \'Undev\' in team projects list' do
    within ".team_projects_list" do
      page.should have_content "Undev"
    end
  end

  step 'I should see \'Undev\' and \'Gitlab\' in team groups list' do
    team_groups = current_team.groups.pluck(:name)
    team_groups.include?("Undev").should == true
    team_groups.include?("Gitlab").should == true

    within ".team_groups_list" do
      page.should have_content "Undev"
      page.should have_content "Gitlab"
    end
  end

  step 'I should not see \'Undev\' in team groups list' do
    within ".team_groups_list" do
      all("li").count.should == 0
    end
  end

  step 'I should not see \'Undev\' in team projects list' do
    within ".team_projects_list" do
      all("li").count.should == 0
    end
  end

  step 'I shoud remove group \'Undev\' from team' do
    group = Group.find_by(name: "Undev")
    within "#group_#{group.id}_team_relationship" do
      page.find("a.btn-remove").click
    end
  end

  step 'I shoud remove project \'Undev\' from team' do
    project = Project.find_by(name: "Undev")
    within "#project_#{project.id}_team_relationship" do
      page.find("a.btn-remove").click
    end
  end

   step 'I open Danger settings' do
     within ".js-toggle-container" do
       find('.js-toggle-button').click
     end
   end

   step 'click on Remove Button' do
     within ".js-toggle-content" do
       find(".btn-remove").click
     end
   end

   step 'I should be redirected on Dashboard page' do
     current_path.should == dashboard_path
   end

   step 'team shoud be deleted' do
     Team.find_by(id: current_team.id).should == nil
   end
end
