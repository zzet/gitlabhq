class ProjectSearchCode < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  When 'I search for term "Welcome to GitLab"' do
    project = Project.find_by(name: "Shop")

    project.repository.index_commits
    project.repository.index_blobs

    fill_in "search", with: "Welcome to GitLab"
    click_button "Go"
    click_link 'Code'
  end

  Then 'I should see files from repository containing "Welcome to GitLab"' do
    page.should have_content "GitLab"
  end

end
