require 'factory_girl_rails'

namespace :db do
  namespace :seed do
    desc "Creates data for previewing notification emails"
    task :notifications => :environment do

      builder = Gitlab::Event::SeedBuilder.new

      builder.create_push_event
    end
  end
end
