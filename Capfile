# Load DSL and Setup Up Stages
require 'capistrano/version'
load 'deploy'

require 'bundler/capistrano'

require 'capistrano/ext/multistage'

require 'undev/capistrano'

# Maintance page with deploy
require 'capistrano/maintenance'

require 'capi/unicorn'

# Uncomment if you will use Airbrake notifications
require 'airbrake/capistrano'

Dir['vendor/gems/*/recipes/*.rb','vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'deploy' if respond_to?(:namespace) # cap2 differentiator
load 'deploy/assets'
load 'config/deploy' # remove this line to skip loading any of the default tasks
