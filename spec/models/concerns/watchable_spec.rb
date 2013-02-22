require 'spec_helper'

#class WatchableEntity
#  include Watchable
#
#  actions_to_watch [:created, :updated, :deleted] 
#end

describe Watchable do
  it 'can register actions thac can be watched' do
#    WatchableEntity.available_actions.should eq [:created, :updated, :deleted] 
  end
end
