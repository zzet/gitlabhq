require_relative '../../lib/coercions/gt_one'

class UnfoldForm
  include Virtus.model

  attribute :since, GtOne
  attribute :to, GtOne
  attribute :bottom, Boolean
  attribute :unfold, Boolean, default: true
  attribute :offset, Integer
end