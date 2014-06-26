web: bundle exec unicorn_rails -p ${PORT:="3000"} -E ${RAILS_ENV:="development"} -c ${UNICORN_CONFIG:="config/unicorn.rb"}
worker: bundle exec sidekiq -q post_receive -q mailer -q system_hook -q project_web_hook -q common -q default -q gitlab_shell -q subscribe
faye: bundle exec rackup private_pub.ru -s thin -E production
