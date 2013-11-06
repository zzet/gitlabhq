require 'spec_helper'

describe SearchContext do
  let(:found_namespace) { create(:namespace, name: 'searchable namespace', path:'another_thing') }
  let(:user) { create(:user, namespace: found_namespace) }
  let!(:found_project) { create(:project, name: 'searchable_project', creator_id: user.id, namespace: found_namespace, public: false) }

  let(:unfound_namespace) { create(:namespace, name: 'unfound namespace', path: 'yet_something_else') }
  let!(:unfound_project) { create(:project, name: 'unfound_project', creator_id: user.id, namespace: unfound_namespace, public: false) }
  let(:public_namespace) { create(:namespace, path: 'something_else',name: 'searchable public namespace') }
  let(:other_user) { create(:user, namespace: public_namespace) }
  let!(:public_project) { create(:project, name: 'searchable_public_project', creator_id: other_user.id, namespace: public_namespace, public: true) }

  describe '#execute' do
    it 'public projects should be searchable' do
      params = {
        search_code:  false,
        search: "searchable",
        project_ids: [found_project.id]
      }
      context = SearchContext.new(user, params)
      results = context.execute
      results[:projects].should == [found_project, public_project]
    end

    it 'namespace name should be searchable' do
      params = {
        search_code:  false,
        search: "searchable namespace",
        project_ids: [found_project.id]
      }
      context = SearchContext.new(user, params)
      results = context.execute
      results[:projects].should == [found_project]
    end
  end
end
