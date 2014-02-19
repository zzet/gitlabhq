source "http://rubygems.org"
source "http://gems.undev.cc" unless ENV["TRAVIS"]

def darwin_only(require_as)
  RUBY_PLATFORM.include?('darwin') && require_as
end

def linux_only(require_as)
  RUBY_PLATFORM.include?('linux') && require_as
end

gem "rails", "~> 4.0.0"

gem "protected_attributes"
gem 'rails-observers'
gem 'actionpack-page_caching'
gem 'actionpack-action_caching'

# Supported DBs
gem "pg"

# Auth
gem "devise", '3.0.4'
gem "devise-async", '0.8.0'
gem 'omniauth', "~> 1.1.3"
gem 'omniauth-google-oauth2'
gem 'omniauth-twitter'
gem 'omniauth-github'

# Search
gem 'elasticsearch-model', git: 'git://github.com/elasticsearch/elasticsearch-rails.git'
gem 'elasticsearch-rails', git: 'git://github.com/elasticsearch/elasticsearch-rails.git'
gem 'elasticsearch-git', '~> 0.0.3'

# Extracting information from a git repository
# Provide access to Gitlab::Git library
gem "gitlab_git", "~> 4.0.0"

# Ruby/Rack Git Smart-HTTP Server Handler
gem 'gitlab-grack', '~> 2.0.0.pre', require: 'grack'

# LDAP Auth
gem 'gitlab_omniauth-ldap', '1.0.3', require: "omniauth-ldap"

# Syntax highlighter
gem "gitlab-pygments.rb", '~> 0.5.4', require: 'pygments.rb'

# Git Wiki
gem "gitlab-gollum-lib", "~> 1.0.2", require: 'gollum-lib'

# Language detection
gem "gitlab-linguist", "~> 2.9.6", require: "linguist"

# API
gem "grape", "~> 0.6.1"
gem "grape-entity", "~> 0.3.0"
gem 'rack-cors', require: 'rack/cors'

# Email validation
gem "email_validator", "~> 1.4.0", :require => 'email_validator/strict'

# Format dates and times
# based on human-friendly examples
gem "stamp"

# Enumeration fields
gem 'enumerize'

# Tree data structure
gem 'closure_tree'

# Pagination
gem "kaminari", "~> 0.15.1"

# HAML
gem "haml-rails"

# Files attachments
gem "carrierwave"

# for aws storage
gem "fog", "~> 1.3.1", group: :aws

# Authorization
gem "six"

# Seed data
gem "seed-fu"

# Markdown to HTML
gem "redcarpet",     "~> 2.2.2"
gem "github-markup", "~> 0.7.4", require: 'github/markup', git: 'https://github.com/gitlabhq/markup.git', ref: '61ade389c1e1c159359338f570d18464a44ddbc4' 

# Diffs
gem 'diffy'

# Asciidoc to HTML
gem  "asciidoctor"

#gem 'activerecord-msgpack_serializer', github: 'zzet/activerecord-msgpack_serializer'

# Application server
group :unicorn do
  gem "unicorn", '~> 4.6.3'
  gem 'unicorn-worker-killer'
end

gem "puma", '~> 2.3.1', group: :puma

#
gem 'request_store'

# State machine
gem "state_machine"

# Issue tags
gem "acts-as-taggable-on"

# Background jobs
gem 'slim'
gem 'sinatra', require: nil
gem 'sidekiq'

# HTTP requests
gem "httparty"

# Colored output to console
gem "colored"

# GitLab settings
gem 'settingslogic'

# Misc
gem "foreman"

# Cache
gem "redis-rails"

# Campfire integration
gem 'tinder', '~> 1.9.2'

# HipChat integration
gem "hipchat", "~> 0.14.0"

# Flowdock integration
gem "gitlab-flowdock-git-hook", "~> 0.4.2"

# d3
gem "d3_rails", "~> 3.1.4"

# underscore-rails
gem "underscore-rails", "~> 1.4.4"

# Sanitize user input
gem "sanitize"

# Protect against bruteforcing
gem "rack-attack"

gem "sass-rails"
gem "coffee-rails"
gem "uglifier"
gem "therubyracer"
gem 'turbolinks'
gem 'jquery-turbolinks'

gem 'select2-rails'
gem 'jquery-atwho-rails', "~> 0.3.3"
gem "jquery-rails",     "2.1.3"
gem "jquery-ui-rails",  "2.0.2"
gem "modernizr",        "2.6.2"
gem "raphael-rails", "~> 2.1.2"
gem 'bootstrap-sass', '~> 3.0'
gem "font-awesome-rails", '~> 3.2'
gem "gemoji", "~> 1.3.0"
gem "gon", '~> 5.0.0'
gem "js-routes"

group :development do
  gem "annotate", "~> 2.6.0.beta2"
  gem "letter_opener"
  gem 'quiet_assets', '~> 1.0.1'
  gem 'rack-mini-profiler'

  # Better errors handler
  gem 'better_errors'
  gem 'binding_of_caller'

  gem 'rails_best_practices'

  # Docs generator
  gem "sdoc"

  # thin instead webrick
  gem 'thin'
end

group :undev do
  # Deploy with Capistrano
  gem "capi"
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'capistrano-maintenance'

  gem 'undev', '>=0.2.1'
end

gem 'airbrake'
gem 'newrelic_rpm'

gem 'rb-inotify', require: linux_only('rb-inotify')

group :development, :staging, :test do
  # Visual email testing
  gem "mail_view", "~> 1.0.3"
  gem 'factory_girl_rails'
end

group :development, :test do
  gem 'coveralls', require: false
  # gem 'rails-dev-tweaks'
  gem 'spinach-rails'
  gem "rspec-rails"
  gem "capybara"
  gem "pry"
  gem 'pry-rails'
  #gem 'pry-rescue'
  #gem 'pry-remote'
  #gem 'pry-stack_explorer'
  #gem 'pry-debugger'
  gem "awesome_print"
  gem "database_cleaner"
  gem "launchy"

  # Prevent occasions where minitest is not bundled in packaged versions of ruby (see #3826)
  gem 'minitest', '~> 4.7.0'

  # Generate Fake data
  gem "ffaker"

  # Guard
  gem 'guard-rspec'
  gem 'guard-spinach'

  # Notification
  gem 'rb-fsevent', require: darwin_only('rb-fsevent')
  gem 'growl',      require: darwin_only('growl')

  # PhantomJS driver for Capybara
  gem 'poltergeist', '~> 1.4.1'

  gem 'spork', '~> 1.0rc'
  gem 'jasmine', '2.0.0.rc5'
end

group :test do
  gem "simplecov", require: false
  gem 'simplecov-vim', require: false
  gem "shoulda-matchers", "~> 2.1.0"
  gem 'email_spec'
  gem "webmock"
  gem 'test_after_commit'
end

group :production do
  gem "gitlab_meta", '6.0'
end
