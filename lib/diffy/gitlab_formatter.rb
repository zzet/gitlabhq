module Diffy
  class GitlabFormatter
    def initialize(diff, options = {})
      @diff = diff
      @options = options
    end
    
    def to_s
      wrap_lines(@diff.map{|line| wrap_line(ERB::Util.h(line))})
    end

    private

    def wrap_line(line)
      cleaned = clean_line(line)
      result_line = case line
                      # when /^(---|\+\+\+|\\\\)/
                      #   '    <li class="diff-comment"><span>' + line.chomp + '</td>'
                    when /^\+/
                      '<td class="line_content new">' + cleaned + '</td>'
                    when /^-/
                      '<td class="line_content old">' + cleaned + '</td>'
                    when /^ /
                      '<td class="line_content unchanged">' + cleaned + '</td>'
                      # when /^@@/
                      #   '<td class="diff-block-info">' + line.chomp + '</td>'
                    end
      result_line = "<tr>" +
        result_line +
        '</tr>'
    end

    # remove +/- or wrap in html
    def clean_line(line)
      if @options[:include_plus_and_minus_in_html]
        line.sub(/^(.)/, '<span class="symbol">\1</span>')
      else
        line.sub(/^./, '')
      end.chomp
    end

    def wrap_lines(lines)
      if lines.empty?
        %'<div class="diff"/>'
      else
        %'<div class="diff">\n  <ul>\n#{lines.join("\n")}\n  </ul>\n</div>\n'
      end
    end

  end
end
