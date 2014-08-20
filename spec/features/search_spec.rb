require 'spec_helper'

describe "Search", feature: true  do
  before do
    ActiveRecord::Base.observers.enable(:user_observer)
    create_indexes_in_es
    login_as :user
    @project = create(:project, namespace: @user.namespace)
    @project.team << [@user, :reporter]
    visit search_path

    within '.search-holder' do
      fill_in "search", with: @project.name[0..3]
      click_button "Search"
    end
  end

  it "should show project in search results" do
    sleep(1)
    page.should have_selector("a#project-#{@project.namespace.path}-#{@project.path}")
    #page.should have_content @project.name
  end
end

