require 'spec_helper'

describe Gitlab::Event::Builder::Service do
  before do
    ActiveRecord::Base.observers.disable :all
    @user = create :user
    @data = {source: @service, user: @user, data: @service}
    @action = "gitlab.created.service"
  end

  Service.implement_services.map {|s| s.new }.each do |service|
    before do
      @service = create :"#{service.to_param}_service"
    end

    it "should respond that can build this data into action" do
      # FIXME repair service actions
      Gitlab::Event::Builder::Service.can_build?(@action, @data[:source]).should be_false
    end

    it "should build events from hash" do
      @events = Gitlab::Event::Builder::Service.build(@action, @data[:source], @data[:user], @data[:data])
    end
  end
end
