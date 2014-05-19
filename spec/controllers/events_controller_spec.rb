require 'spec_helper'

describe EventsController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)

    project.team << [user, :master]
  end

  describe "index" do
    it "should get project events" do
      get :index, dashboard: 'Project'
      response.should be_success
    end
  end
end
