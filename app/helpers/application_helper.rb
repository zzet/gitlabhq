require 'digest/md5'
require 'uri'

module ApplicationHelper
  COLOR_SCHEMES = {
    1 => 'white',
    2 => 'dark',
    3 => 'solarized-dark',
    4 => 'monokai',
  }
  COLOR_SCHEMES.default = 'white'

  # Helper method to access the COLOR_SCHEMES
  #
  # The keys are the `color_scheme_ids`
  # The values are the `name` of the scheme.
  #
  # The preview images are `name-scheme-preview.png`
  # The stylesheets should use the css class `.name`
  def color_schemes
    COLOR_SCHEMES.freeze
  end

  # Check if a particular controller is the current one
  #
  # args - One or more controller names to check
  #
  # Examples
  #
  #   # On TreeController
  #   current_controller?(:tree)           # => true
  #   current_controller?(:commits)        # => false
  #   current_controller?(:commits, :tree) # => true
  def current_controller?(*args)
    args.any? { |v| v.to_s.downcase == controller.controller_name }
  end

  # Check if a particular action is the current one
  #
  # args - One or more action names to check
  #
  # Examples
  #
  #   # On Projects#new
  #   current_action?(:new)           # => true
  #   current_action?(:create)        # => false
  #   current_action?(:new, :create)  # => true
  def current_action?(*args)
    args.any? { |v| v.to_s.downcase == action_name }
  end

  def group_icon(group_path)
    group = Group.find_by(path: group_path)
    if group && group.avatar.present?
      group.avatar.url
    else
      image_path('no_group_avatar.png')
    end
  end

  def avatar_icon(user_email = '', size = nil)
    user = User.find_by(email: user_email)

    if user
      user.avatar_url(size) || default_avatar
    else
      gravatar_icon(user_email, size)
    end
  end

  def gravatar_icon(user_email = '', size = nil)
    GravatarService.new.execute(user_email, size) ||
      default_avatar
  end

  def default_avatar
    image_path('no_avatar.png')
  end

  def last_commit(project)
    if project.repo_exists?
      time_ago_with_tooltip(project.repository.commit.committed_date)
    else
      "Never"
    end
  rescue
    "Never"
  end

  def grouped_options_refs
    repository = @project.repository

    options = [
      ["Branches", repository.branch_names],
      ["Tags", VersionSorter.rsort(repository.tag_names)]
    ]

    # If reference is commit id - we should add it to branch/tag selectbox
    if(@ref && !options.flatten.include?(@ref) &&
       @ref =~ /^[0-9a-zA-Z]{6,52}$/)
      options << ["Commit", [@ref]]
    end

    grouped_options_for_select(options, @ref || @project.default_branch)
  end

  def emoji_autocomplete_source
    # should be an array of strings
    # so to_s can be called, because it is sufficient and to_json is too slow
    Emoji.names.to_s
  end

  def app_theme
    Gitlab::Theme.css_class_by_id(current_user.try(:theme_id))
  end

  def user_color_scheme_class
    COLOR_SCHEMES[current_user.try(:color_scheme_id)] if defined?(current_user)
  end

  # Define whenever show last push event
  # with suggestion to create MR
  def show_last_push_widget?(event)
    # Skip if event is not about added or modified non-master branch
    return false unless event

    project = event.target
    push = event.source

    return false unless project

    unless !push.to_default_branch? && push.branch? && !push.deleted_branch?
      return false
    end

    # Skip if project repo is empty or MR disabled
    return false unless project && !project.empty_repo? && project.merge_requests_enabled

    # Skip if user already created appropriate MR
    #return false if project.merge_requests.where(source_branch: push.branch_name).opened.any?

    # Skip if user removed branch right after that
    #return false unless project.repository.branch_names.include?(push.branch_name)

    true
  end

  def hexdigest(string)
    Digest::SHA1.hexdigest string
  end

  def project_last_activity project
    if project.last_activity_at
      time_ago_in_words(project.last_activity_at) + " ago"
    else
      "Never"
    end
  end

  def authbutton(provider, size = 64)
    file_name = "#{provider.to_s.split('_').first}_#{size}.png"
    image_tag(image_path("authbuttons/#{file_name}"), alt: "Sign in with #{provider.to_s.titleize}")
  end

  def simple_sanitize(str)
    sanitize(str, tags: %w(a span))
  end

  def image_url(source)
    # prevent relative_root_path being added twice (it's part of root_url and path_to_image)
    root_url.sub(/#{root_path}$/, path_to_image(source))
  end

  alias_method :url_to_image, :image_url

  def users_select_tag(id, opts = {})
    css_class = "ajax-users-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, class: css_class)
  end

  def projects_select_tag(id, opts = {})
    css_class = "ajax-projects-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, class: css_class)
  end

  def groups_select_tag(id, opts = {})
    css_class = "ajax-groups-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, class: css_class)
  end

  def teams_select_tag(id, opts = {})
    css_class = "ajax-teams-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, class: css_class)
  end

  def body_data_page
    path = controller.controller_path.split('/')
    namespace = path.first if path.second

    [namespace, controller.controller_name, controller.action_name].compact.join(":")
  end

  # shortcut for gitlab config
  def gitlab_config
    Gitlab.config.gitlab
  end

  # shortcut for gitlab extra config
  def extra_config
    Gitlab.config.extra
  end

  def public_icon
    content_tag :i, nil, class: 'icon-globe cblue'
  end

  def private_icon
    content_tag :i, nil, class: 'icon-lock cgreen'
  end

  def git_protocol_icon(git_protocol_enabled)
    content_tag :i, nil, class: "#{git_protocol_enabled ? "icon-ok" : "icon-off" }"
  end

  def permission_key?(key)
    %w(group_access team_access project_access).include?(key)
  end

  def search_placeholder
    if @project && @project.persisted?
      "Search in this project"
    elsif @group && @group.persisted?
      "Search in this group"
    elsif @team && @team.persisted?
      "Search in this team"
    else
      "Search"
    end
  end

  def first_line(str)
    lines = str.split("\n")
    line = lines.first
    line += "..." if lines.size > 1
    line
  end

  def broadcast_message
    BroadcastMessage.current
  end

  def highlight_js(&block)
    string = capture(&block)

    content_tag :div, class: "highlighted-data #{user_color_scheme_class}" do
      content_tag :div, class: 'highlight' do
        content_tag :pre do
          content_tag :code do
            string.html_safe
          end
        end
      end
    end
  end

  def time_ago_with_tooltip(date, placement = 'top', html_class = 'time_ago')
    capture_haml do
      haml_tag :time, date.to_s,
        class: html_class, datetime: date.getutc.iso8601, title: date.stamp("Aug 21, 2011 9:23pm"),
        data: { toggle: 'tooltip', placement: placement }

      haml_tag :script, "$('." + html_class + "').timeago().tooltip()"
    end.html_safe
  end

  def render_markup(file_name, file_content)
    GitHub::Markup.render(file_name, file_content).html_safe
  end

  def spinner(text = nil, visible = false)
    css_class = "loading"
    css_class << " hide" unless visible

    content_tag :div, class: css_class do
      content_tag(:i, nil, class: 'icon-spinner icon-spin') + text
    end
  end

  def link_to_target(target)
    link_to target do
      title = content_tag(:span, target.name)

      if target.instance_of?(Project)
        namespace = content_tag(:span, "#{target.namespace.human_name} / ", class: 'namespace-name')
        title = namespace + title
      end

      title
    end
  end

  def link_to_or_deleted(target, name)
    if target.present?
      link_to_target target
    else
      "(deleted #{name})"
    end
  end

  def link_to(name = nil, options = nil, html_options = nil, &block)
    begin
      uri = URI(options)
      host = uri.host
      absolute_uri = uri.absolute?
    rescue URI::InvalidURIError, ArgumentError
      host = nil
      absolute_uri = nil
    end

    # Add "nofollow" only to external links
    if host && host != Gitlab.config.gitlab.host && absolute_uri
      if html_options
        if html_options[:rel]
          html_options[:rel] << " nofollow"
        else
          html_options.merge!(rel: "nofollow")
        end
      else
        html_options = Hash.new
        html_options[:rel] = "nofollow"
      end
    end

    super
  end
end
