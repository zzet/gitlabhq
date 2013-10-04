# == Schema Information
#
# Table name: events
#
#  id              :integer          not null, primary key
#  author_id       :integer
#  action          :string(255)
#  source_id       :integer
#  source_type     :string(255)
#  target_id       :integer
#  target_type     :string(255)
#  data            :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  parent_event_id :integer
#

require 'spec_helper'

describe Event do
  pending "add some examples to (or delete) #{__FILE__}"
end
