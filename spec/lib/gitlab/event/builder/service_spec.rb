require 'spec_helper'

describe Gitlab::Event::Builder::Service do
  before do
    @service = create :service
    @user = create :user
    @data = {target: @service, user: @user, data: @service}
    @action = "gitlab.created.service"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Service.can_build?(@action, @data).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Service.build(@action, @data[:target], @data[:user], @data[:data])
  end

end
