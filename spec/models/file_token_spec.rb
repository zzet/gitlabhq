# == Schema Information
#
# Table name: file_tokens
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  project_id    :integer
#  token         :string(255)
#  file          :string(255)
#  last_usage_at :datetime
#  usage_count   :integer          default(0)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  source_ref    :string(255)
#

require 'spec_helper'

describe FileToken do
  pending "add some examples to (or delete) #{__FILE__}"
end
