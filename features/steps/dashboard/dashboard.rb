class Dashboard < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  Then 'I should see "New Project" link' do
    page.should have_link "New project"
  end

  Then 'I should see "Shop" project link' do
    page.should have_link "Shop"
  end

  Then 'I should see last push widget' do
    page.should have_content "You pushed to new_design"
    page.should have_link "Create Merge Request"
  end

  And 'I click "Create Merge Request" link' do
    click_link "Create Merge Request"
  end

  Then 'I see prefilled new Merge Request page' do
    current_path.should == new_project_merge_request_path(@project)
    find("#merge_request_target_project_id").value.should == @project.id.to_s
    find("#merge_request_source_branch").value.should == "new_design"
    find("#merge_request_target_branch").value.should == "master"
  end

  Given 'user with name "John Doe" joined project "Shop"' do
    user = create(:user, {name: "John Doe"})
    project = Project.find_by(name: "Shop")
    project.team << [user, :master]
    users_project = user.users_projects.find_by(project_id: project.id)

    Gitlab::Event::Factory.create_events("gitlab.create.users_project", {
        source: users_project,
        user: user,
        data: users_project,
        uniq_hash: "123"
    })
  end

  Then 'I should see "John Doe joined project at Shop" event' do
    page.should have_content "John Doe added John Doe to #{project.name_with_namespace}"
  end

  And 'user with name "John Doe" left project "Shop"' do
    user = User.find_by(name: "John Doe")
    project = Project.find_by(name: "Shop")
    users_project = user.users_projects.find_by(project_id: project.id)

    users_project.destroy
  end

  Then 'I should see "John Doe left project at Shop" event' do
    page.save_screenshot("event_left.png")
    page.should have_content "John Doe left project at #{project.name_with_namespace}"
  end

  And 'I have group with projects' do
    @group   = create(:group)
    @project = create(:project, namespace: @group)

    @project.team << [current_user, :master]
  end

  Then 'I should see projects list' do
    @user.authorized_projects.all.each do |project|
      page.should have_link project.name_with_namespace
    end
  end

  Then 'I should see groups list' do
    Group.all.each do |group|
      page.should have_link group.name
    end
  end

  And 'group has a projects that does not belongs to me' do
    @forbidden_project1 = create(:project, group: @group)
    @forbidden_project2 = create(:project, group: @group)
  end

  Then 'I should see 1 project at group list' do
    page.find('span.last_activity/span').should have_content('1')
  end

  def project
    @project ||= Project.find_by(name: "Shop")
  end
end
