require 'spec_helper'

describe SearchHelper do
  # Override simple_sanitize for our testing purposes
  def simple_sanitize(str)
    str
  end

  describe 'search_autocomplete_source' do
    context "with no current user" do
      before do
        allow(self).to receive(:current_user).and_return(nil)
      end

      it "it returns nil" do
        search_autocomplete_opts("q").should be_nil
      end
    end

    context "with a user" do
      let(:user)   { create(:user) }

      before do
        allow(self).to receive(:current_user).and_return(user)
      end

      it "includes the user's groups" do
        create(:group).add_owner(user)
        #sleep 1
        search_autocomplete_opts("gro").size.should == 1
      end

      it "includes the user's projects" do
        group = create(:group)
        group.add_owner(user)
        project = create(:project, namespace: group)
        #sleep 1
        search_autocomplete_opts(project.name).size.should == 1
      end
    end
  end
end
