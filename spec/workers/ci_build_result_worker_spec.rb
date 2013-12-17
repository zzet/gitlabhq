require 'spec_helper'

describe CiBuildResultWorker do

  let!(:project) { create(:project) }

  let!(:build_result) do
    json = File.open(Rails.root.join('spec', 'fixtures', 'ci_build_result.json')).read
    JSON.parse(json)
  end

  let!(:build) do
    create(:ci_build, id: 10, target_project: project,
           source_project: project,
           source_sha: '83029b76cc49c8c3a7d8910dc30931500fa429f0'
    )
  end

  context "Jenkins build" do
    it "update build status" do
      CiBuildResultWorker.new.perform(build_result)
      build.reload
      expect(build.state).to eq("success")
    end
  end
end
