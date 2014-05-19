web: bundle exec unicorn_rails -p $PORT -E development -c config/unicorn_development.rb
worker: bundle exec sidekiq -q post_receive,mailer,system_hook,project_web_hook,common,default,gitlab_shell,subscribe
faye: bundle exec rackup private_pub.ru -s thin -E production