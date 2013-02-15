require 'spec_helper'

describe Gitlab::Event::Builder::Namespace do
  before do
    @namespace = create :namespace
    @user = create :user
    @data = {target: @namespace, user: @user, data: @namespace}
    @action = "gitlab.created.namespace"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Namespace.can_build?(@action, @data).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Namespace.build(@action, @data[:target], @data[:user], @data[:data])
  end


end
