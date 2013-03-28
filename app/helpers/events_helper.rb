module EventsHelper
  def link_to_event_author(event)
    author = event.author

    if author
      link_to author.name, user_path(author.username)
    else
      # TODO. Add save event author into event data
      "Deleted user"
    end
  end

  def event_action_name(event)
    target = event.source_type.titleize.downcase
    [event.action, target].join(" ")
  end

  def event_filter_link key, tooltip
    key = key.to_s
    inactive = if @event_filter.active? key
                 nil
               else
                 'inactive'
               end

    content_tag :div, class: "filter_icon #{inactive}" do
      link_to dashboard_path, class: 'has_tooltip event_filter_link', id: "#{key}_event_filter", 'data-original-title' => tooltip do
        content_tag :i, nil, class: icon_for_event[key]
      end
    end
  end

  def icon_for_event
    {
      EventFilter.group => "icon-user",
      EventFilter.issue => "icon-comments",
      EventFilter.merge_request => "icon-check",
      EventFilter.milestone => "icon-check",
      EventFilter.project => "icon-check",
      EventFilter.protected_branch => "icon-check",
      EventFilter.snippet => "icon-check",
      EventFilter.user => "icon-user",
      EventFilter.user_team => "icon-user"
      #EventFilter.push     => "icon-upload-alt",
      #EventFilter.merged   => "icon-check",
      #EventFilter.comments => "icon-comments",
      #EventFilter.team     => "icon-user",
    }
  end

  def link_to_author(event)
    author = event.author

    if author
      link_to author.name, user_path(author.username)
    else
      # TODO. Add save event author into event data
      "Deleted user"
    end
  end
end
