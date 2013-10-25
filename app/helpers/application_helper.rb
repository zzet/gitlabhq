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

  def avatar_icon(user_email = '', size = nil)
    user = User.find_by_email(user_email)
    if user && user.avatar.present?
      user.avatar.url
    else
      gravatar_icon(user_email, size)
    end
  end

  def gravatar_icon(user_email = '', size = nil)
    size = 40 if size.nil? || size <= 0

    if !Gitlab.config.gravatar.enabled || user_email.blank?
      'no_avatar.png'
    else
      gravatar_url = request.ssl? || gitlab_config.https ? Gitlab.config.gravatar.ssl_url : Gitlab.config.gravatar.plain_url
      user_email.strip!
      sprintf gravatar_url, hash: Digest::MD5.hexdigest(user_email.downcase), size: size
    end
  end

  def last_commit(project)
    if project.repo_exists?
      time_ago_in_words(project.repository.commit.committed_date) + " ago"
    else
      "Never"
    end
  rescue
    "Never"
  end

  def grouped_options_refs(destination = :tree)
    repository = @project.repository

    options = [
      ["Branch", repository.branch_names ],
      [ "Tag", repository.tag_names ]
    ]

    # If reference is commit id -
    # we should add it to branch/tag selectbox
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
    return false unless event && event.last_push_to_non_root? && !event.rm_ref?

    project = event.project

    # Skip if project repo is empty or MR disabled
    return false unless project && !project.empty_repo? && project.merge_requests_enabled

    # Skip if user already created appropriate MR
    return false if project.merge_requests.where(source_branch: event.branch_name).opened.any?

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

  def project_last_push project
    if project.last_pushed_at
      time_ago_in_words(project.last_pushed_at) + " ago"
    else
      "Never"
    end
  end

  def authbutton(provider, size = 64)
    file_name = "#{provider.to_s.split('_').first}_#{size}.png"
    image_tag("authbuttons/#{file_name}",
              alt: "Sign in with #{provider.to_s.titleize}")
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
end
