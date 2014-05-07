# == Schema Information
#
# Table name: services
#
#  id                 :integer          not null, primary key
#  type               :string(255)
#  title              :string(255)
#  project_id         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  state              :string(255)
#  service_pattern_id :integer
#  public_state       :string(255)
#  active_state       :string(255)
#  description        :text
#  recipients         :text
#  api_key            :string(255)
#

require 'spec_helper'

describe Service do

  describe "Associations" do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:project_id) }
  end

  describe "Test Button" do
    before do
      @service = Service.new
    end

    describe "Testable" do
      let (:project) { create :project }

      before do
        @service.stub(
          project: project
        )
        @testable = @service.can_test?
      end

      describe :can_test do
        it { @testable.should == true }
      end
    end

    describe "With commits" do
      let (:project) { create :project }

      before do
        @service.stub(
          project: project
        )
        @testable = @service.can_test?
      end

      describe :can_test do
        it { @testable.should == true }
      end
    end
  end
end
