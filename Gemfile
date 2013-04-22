source "https://rubygems.org"

def darwin_only(require_as)
  RUBY_PLATFORM.include?('darwin') && require_as
end

def linux_only(require_as)
  RUBY_PLATFORM.include?('linux') && require_as
end

gem "rails", "3.2.13"

# Supported DBs
gem "mysql2", group: :mysql
gem "pg", group: :postgres

# Auth
gem "devise"
gem 'omniauth', "~> 1.1.3"
gem 'omniauth-google-oauth2'
gem 'omniauth-twitter'
gem 'omniauth-github'

# Extracting information from a git repository
# Since gollum requires grit we cannot use gitlab-grit gem name any more. Use grit instead
gem "grit", '~> 2.5.0', git: 'https://github.com/gitlabhq/grit.git', ref: '42297cdcee16284d2e4eff23d41377f52fc28b9d'
gem 'grit_ext', '~> 0.8.1'

# Ruby/Rack Git Smart-HTTP Server Handler
gem 'gitlab-grack', '~> 1.0.0', require: 'grack'

# LDAP Auth
gem 'gitlab_omniauth-ldap', '1.0.2', require: "omniauth-ldap"

# Syntax highlighter
gem "gitlab-pygments.rb", '~> 0.3.2', require: 'pygments.rb'

# Language detection
gem "github-linguist", "~> 2.3.4" , require: "linguist"

# API
gem "grape", "~> 0.3.1"
gem "grape-entity", "~> 0.2.0"

# Format dates and times
# based on human-friendly examples
gem "stamp"

# Enumeration fields
gem 'enumerize'

# Pagination
gem "kaminari", "~> 0.14.1"

# HAML
gem "haml-rails"

# Files attachments
gem "carrierwave"

# Authorization
gem "six"

# Seed data
gem "seed-fu"

# Markdown to HTML
gem "redcarpet",     "~> 2.2.2"
gem "github-markup", "~> 0.7.4", require: 'github/markup'

# Servers
gem "puma", '~> 2.0.0.b7'

# State machine
gem "state_machine"

# Issue tags
gem "acts-as-taggable-on", "2.3.3"

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

# Git Wiki
gem "gollum-lib", "~> 1.0.0"

# Misc
gem "foreman"

# Cache
gem "redis-rails"

group :assets do
  gem "sass-rails",   "~> 3.2.5"
  gem "coffee-rails", "~> 3.2.2"
  gem "uglifier",     "~> 1.3.0"
  gem "therubyracer"

  gem 'chosen-rails',     "0.9.8"
  gem 'select2-rails'
  gem 'jquery-atwho-rails', "0.1.7"
  gem "jquery-rails",     "2.1.3"
  gem "jquery-ui-rails",  "2.0.2"
  gem "modernizr",        "2.6.2"
  gem "raphael-rails",    git: "https://github.com/gitlabhq/raphael-rails.git"
  gem 'bootstrap-sass',   "2.2.1.1"
  gem "font-awesome-sass-rails", "~> 3.0.0"
  gem "gemoji", "~> 1.2.1", require: 'emoji/railtie'
  gem "gon"
  gem "js-routes"
end

group :development do
  gem "annotate", git: "https://github.com/ctran/annotate_models.git"
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

group :development, :test do
  gem 'coveralls', require: false
  gem 'rails-dev-tweaks'
  gem 'spinach-rails'
  gem "rspec-rails"
  gem "capybara"
  gem "pry"
  gem "awesome_print"
  gem "database_cleaner"
  gem "launchy"
  gem 'factory_girl_rails'

  # Generate Fake data
  gem "ffaker"

  # Guard
  gem 'guard-rspec'
  gem 'guard-spinach'

  # Notification
  gem 'rb-fsevent', require: darwin_only('rb-fsevent')
  gem 'growl',      require: darwin_only('growl')
  gem 'rb-inotify', require: linux_only('rb-inotify')

  # PhantomJS driver for Capybara
  gem 'poltergeist', git: 'https://github.com/jonleighton/poltergeist.git', ref: '9645b52009e258921b860d3b7601d00008b22c45'

  gem 'spork', '~> 1.0rc'
end

group :test do
  gem "simplecov", require: false
  gem "shoulda-matchers", "1.3.0"
  gem 'email_spec'
  gem "webmock"
  gem 'test_after_commit'
end

group :production do
  gem "gitlab_meta", '5.0'
end
