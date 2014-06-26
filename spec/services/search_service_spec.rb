require 'spec_helper'

describe 'SearchService' do
  let!(:user) { create(:user, namespace: found_namespace) }
  let!(:public_user) { create(:user, namespace: public_namespace) }
  let!(:internal_user) { create(:user, namespace: internal_namespace) }

  let!(:found_namespace) { create(:namespace, name: 'searchable namespace', path:'another_thing') }
  let!(:unfound_namespace) { create(:namespace, name: 'unfound namespace', path: 'yet_something_else') }
  let!(:internal_namespace) { create(:namespace, name: 'searchable internal namespace', path: 'something_internal') }
  let!(:public_namespace) { create(:namespace, name: 'searchable public namespace', path: 'something_public') }

  let(:found_project) { create(:project, :private, name: 'searchable_project', creator_id: user.id, namespace: found_namespace) }
  let(:unfound_project) { create(:project, :private, name: 'unfound_project', creator_id: user.id, namespace: unfound_namespace) }
  let(:internal_project) { create(:project, :internal, name: 'searchable_internal_project', creator_id: internal_user.id, namespace: internal_namespace) }
  let(:public_project) { create(:project, :public, name: 'searchable_public_project', creator_id: public_user.id, namespace: public_namespace) }

  describe '#execute' do
    before do
      create_indexes_in_es
      user
      public_user
      internal_user

      found_namespace
      unfound_namespace
      internal_namespace
      public_namespace

      found_project
      unfound_project
      internal_project
      public_project
    end

    context 'unauthenticated' do
      it 'should return public projects only' do
        context = SearchService.new(nil, search: "searchable")
        results = context.global_search
        results[:projects][:records].should have(1).items
        results[:projects][:records].should include(public_project)
      end
    end

    context 'authenticated' do
      it 'should return public, internal and private projects' do
        context = SearchService.new(user, search: "searchable")
        results = context.global_search
        results[:projects][:records].should have(3).items
        results[:projects][:records].should include(public_project)
        results[:projects][:records].should include(found_project)
        results[:projects][:records].should include(internal_project)
      end

      it 'should return only public & internal projects' do
        context = SearchService.new(internal_user, search: "searchable")
        results = context.global_search
        results[:projects][:records].should have(2).items
        results[:projects][:records].should include(internal_project)
        results[:projects][:records].should include(public_project)
      end
    end
  end
end
