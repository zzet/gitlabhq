module Gitlab
  module Diff
    class GritParser < Parser
      def initialize(diff)
        @lines = diff.diff.lines.to_a
        @new_path = diff.new_path
      end
    end
  end
end
