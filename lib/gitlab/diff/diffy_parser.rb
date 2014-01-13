module Gitlab
  module Diff
    class DiffyParser < Parser
      def initialize(diff)
        @lines = diff.diff.scan(/.*\n/)
        @new_path = ''
      end

      def empty?
        @lines.empty?
      end
    end
  end
end
