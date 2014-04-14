class ProjectCiBuild < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include Spinach::DSL

  Given "Project has Jenkins Ci service" do
    create(:active_public_enabled_jenkins_service, project: @project)
  end

  Given 'Ci build' do
    last_commit = @project.repository.commits('master', '', 1).last
    create(:ci_build, target_project: @project,
           source_project: @project,
           source_sha: last_commit.id,
           target_project: nil
    )
  end

  Given 'I click on more info' do
    page.find('.icon-info-sign').click
  end

  Then 'I see additional parameters' do
    page.should have_selector('.popover a', count: 1)
  end

  Then 'I rebuild' do
    page.find('.popover .icon-repeat', visible: false).click
    sleep 2
  end
end
