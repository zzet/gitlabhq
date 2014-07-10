class SearchDecorator
  TYPE_MAP = {
      'project' => :projects?,
      'group' => :groups?,
      'team' => :teams?,
      'merge_request' => :merge_requests?,
      'issue' => :issues?,
      'code' => :code?,
      'commits' => :commits?,
      'user' => :users?,
  }

  def initialize(search_result, type = '')
    @sr = search_result
    @t = type
  end

  def type
    ([@t] + TYPE_MAP.keys).each do |key|
      if key && self.respond_to?(TYPE_MAP[key]) && self.send(TYPE_MAP[key])
        return key
      end
    end

    ''
  end

  def projects?
    @sr[:projects].present? && @sr[:projects][:total_count] > 0
  end

  def groups?
    @sr[:groups].present? && @sr[:groups][:total_count] > 0
  end

  def teams?
    @sr[:teams].present? && @sr[:teams][:total_count] > 0
  end

  def merge_requests?
    @sr[:merge_requests].present? && @sr[:merge_requests][:total_count] > 0
  end

  def issues?
    @sr[:issues].present? && @sr[:issues][:total_count] > 0
  end

  def code?
    @sr[:repositories].present? && @sr[:repositories][:blobs][:total_count] > 0
  end

  def commits?
    @sr[:repositories].present? && @sr[:repositories][:commits][:total_count] > 0
  end

  def users?
    @sr[:users].present? && @sr[:users][:total_count] > 0
  end

  def founded_languages
    @sr[:repositories][:blobs][:languages].select { |lang| lang['count'] > 0 }
  end

  def [](key)
    @sr[key]
  end
end
