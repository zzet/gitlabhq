require 'spec_helper'

describe API::API do
  include ApiHelpers
  before(:each) { ActiveRecord::Base.observers.enable(:user_observer) }
  after(:each) { ActiveRecord::Base.observers.disable(:user_observer) }

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, namespace: user.namespace ) }
  let(:group) { create(:group, owner: user) }
  let(:second_project) { create(:empty_project, namespace: user.namespace ) }
  before { project.team << [user, :reporter] }

  describe "favourites api" do

    context "#create" do
      it "should create favourite" do
        post api("/favourites/", user), favourite: { type: 'project', id: project.id }
        response.status.should == 201
      end
    end

    context "#delete" do
      before do
        FavouritesService.new(user).add(project)
      end

      it "should destroy favourite" do
        delete api("/favourites/#{project.class.name.underscore}/#{project.id}", user)
        response.status.should == 204

        favourite = user.personal_favourites.find_by(entity_id: project.id, entity_type: 'Project')
        expect(favourite).to be_nil
      end
    end
  end
end
