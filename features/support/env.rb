require 'simplecov' unless ENV['CI']

if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
end

ENV['RAILS_ENV'] = 'test'
require './config/environment'

require 'rspec'
require 'rspec/expectations'
require 'database_cleaner'
require 'spinach/capybara'
require 'sidekiq/testing/inline'


%w(valid_commit valid_commit_with_alt_email big_commits select2_helper test_env).each do |f|
  require Rails.root.join('spec', 'support', f)
end

Dir["#{Rails.root}/features/steps/shared/*.rb"].each {|file| require file}

WebMock.allow_net_connect!
#
# JS driver
#
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: false, timeout: 90)
end
Spinach.hooks.on_tag("javascript") do
  ::Capybara.current_driver = ::Capybara.javascript_driver
end
Capybara.default_wait_time = 6
Capybara.ignore_hidden_elements = false

DatabaseCleaner.strategy = :truncation

Spinach.hooks.before_scenario do
  sleep 0.2
  TestEnv.setup_stubs
  Gitlab::Event::Factory.unstub(:call)
  Gitlab.config.stub(:corporate_email_domains) { ["email.com"] }
  PrivatePub.stub(publish_to: true)
  DatabaseCleaner.start
end

Spinach.hooks.after_scenario do
  sleep 0.2
  Gitlab::Event::Factory.stub(call: true)
  PrivatePub.unstub(:publish_to)
  DatabaseCleaner.clean
  sleep 1
end

Spinach.hooks.before_run do
  TestEnv.init(mailer: false, init_repos: true, repos: false)
  RSpec::Mocks::setup self

  include FactoryGirl::Syntax::Methods
end
