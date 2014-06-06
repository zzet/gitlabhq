class SearchDecorator
  def initialize(search_result)
    @sr = search_result
  end

  def type
    return 'project' if projects?
    return 'group' if groups?
    return 'team' if teams?
    return 'merge_request' if merge_requests?
    return 'issue' if issues?
    return 'code' if code?
    return 'commits' if commits?
    return 'user' if users?
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
    @sr[:repositories][:commits][:total_count] > 0
  end

  def users?
    @sr[:users].present? && @sr[:users][:total_count] > 0
  end

  def [](key)
    @sr[key]
  end
end
