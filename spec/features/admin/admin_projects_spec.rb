require 'spec_helper'

describe "Admin::Projects", feature: true  do
  before do
    Project.__elasticsearch__.create_index! force: true
    @project = create(:project)
    #sleep 1
    login_as :admin
  end

  describe "GET /admin/projects" do
    before do
      visit admin_projects_path
    end

    it "should be ok" do
      current_path.should == admin_projects_path
    end

    it "should have projects list" do
      page.should have_content(@project.name)
    end
  end

  describe "GET /admin/projects/:id" do
    before do
      visit admin_projects_path
      click_link "#{@project.name}"
    end

    it "should have project info" do
      page.should have_content(@project.path)
      page.should have_content(@project.name)
    end
  end
end
