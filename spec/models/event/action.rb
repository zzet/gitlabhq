require 'spec_helper'

describe Event::Action do
  describe "should return array of available actions actions" do
    action_types = Event::Action.available_actions
    action_types.should be_kind_of Array
  end
end
