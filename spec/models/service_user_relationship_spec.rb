# == Schema Information
#
# Table name: service_user_relationships
#
#  id         :integer          not null, primary key
#  service_id :integer
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe ServiceUserRelationship do
  pending "add some examples to (or delete) #{__FILE__}"
end
