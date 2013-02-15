require 'spec_helper'

describe Gitlab::Event::Builder::Note do
  before do
    @note = create :note
    @user = create :user
    @data = {target: @note, user: @user, data: @note}
    @action = "gitlab.created.note"
  end

  it "should respond that can build this data into action" do
    Gitlab::Event::Builder::Note.can_build?(@action, @data).should be_true
  end

  it "should build events from hash" do
    @events = Gitlab::Event::Builder::Note.build(@action, @data[:target], @data[:user], @data[:data])
  end
end
