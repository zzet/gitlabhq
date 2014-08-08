class Spinach::Features::TeamPages < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include Select2Helper

  step 'I have group with projects' do
    @group   = create(:group)
    @group.add_owner(current_user)
    @project = create(:project, namespace: @group)
    @event   = create(:closed_issue_event, project: @project)

    @project.team << [current_user, :master]

    current_user.can_create_team = true
    current_user.save
  end

  step 'I click new team link' do
    click_link "New team"
  end

  step 'submit form with new team info' do
    fill_in 'team_name', with: 'OpenSource'
    fill_in 'team_description', with: 'Team for develop opensource products'
    click_button "Create team"
  end

  step 'I should be redirected to team page' do
    current_path.should == team_path(Team.last)
  end

  step 'I should see newly created team' do
    page.should have_content "OpenSource"
    page.should have_content "Team for develop opensource products"
  end

   step 'I should be redirected to dashbord team page' do
     current_path.should == teams_dashboard_path
   end
end
