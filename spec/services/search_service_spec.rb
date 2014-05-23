require 'spec_helper'

describe 'SearchService' do
  let!(:user) { create(:user, namespace: found_namespace) }
  let!(:public_user) { create(:user, namespace: public_namespace) }
  let!(:internal_user) { create(:user, namespace: internal_namespace) }

  let!(:found_namespace) { create(:namespace, name: 'searchable namespace', path:'another_thing') }
  let!(:unfound_namespace) { create(:namespace, name: 'unfound namespace', path: 'yet_something_else') }
  let!(:internal_namespace) { create(:namespace, name: 'searchable internal namespace', path: 'something_internal') }
  let!(:public_namespace) { create(:namespace, name: 'searchable public namespace', path: 'something_public') }

  let!(:found_project) { create(:project, :private, name: 'searchable_project', creator_id: user.id, namespace: found_namespace) }
  let!(:unfound_project) { create(:project, :private, name: 'unfound_project', creator_id: user.id, namespace: unfound_namespace) }
  let!(:internal_project) { create(:project, :internal, name: 'searchable_internal_project', creator_id: internal_user.id, namespace: internal_namespace) }
  let!(:public_project) { create(:project, :public, name: 'searchable_public_project', creator_id: public_user.id, namespace: public_namespace) }

  describe '#execute' do
    context 'unauthenticated' do
      it 'should return public projects only' do
        context = SearchService.new(nil, search: "searchable")
        projects = context.global_search[:projects][:results]
        projects.should have(1).items
        es_result_ids(projects).should include(public_project.id)
      end
    end

    context 'authenticated' do
      it 'should return public, internal and private projects' do
        context = SearchService.new(user, search: "searchable")
        projects = context.global_search[:projects][:results]
        projects.should have(3).items
        es_result_ids(projects).should include(public_project.id)
        es_result_ids(projects).should include(found_project.id)
        es_result_ids(projects).should include(internal_project.id)
      end

      it 'should return only public & internal projects' do
        context = SearchService.new(internal_user, search: "searchable")
        projects = context.global_search[:projects][:results]
        projects.should have(2).items
        es_result_ids(projects).should include(internal_project.id)
        es_result_ids(projects).should include(public_project.id)
      end
    end
  end

  def es_result_ids(results)
    results.map(&:_source).map(&:id)
  end
end
