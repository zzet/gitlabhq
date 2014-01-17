class DashboardProjects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  Then 'I should see projects list' do
    @user.authorized_projects.find_each do |project|
      page.should have_link project.name_with_namespace
    end
  end
end
