root = Gitlab.config.gitlab_shell.repos_path

projects = [
  { path: 'underscore.git',              git: 'https://github.com/documentcloud/underscore.git' },
  { path: 'diaspora.git',                git: 'https://github.com/diaspora/diaspora.git' },
  { path: 'd3.git', git: 'git@github.com:mbostock/d3.git' },
  { path: 'GuzzleBundle.git', git: 'git@github.com:ludofleury/GuzzleBundle.git' },
  { path: 'nu.git', git: 'git@github.com:timburks/nu.git' },
  { path: 'prototype.git', git: 'git@github.com:sstephenson/prototype.git' },
  { path: 'passenger.git', git: 'git@github.com:FooBarWidget/passenger.git' },
  { path: 'scriptaculous.git', git: 'git@github.com:madrobby/scriptaculous.git' },
  { path: 'rails.git', git: 'git@github.com:rails/rails.git' },
  { path: 'mootools-core.git', git: 'git@github.com:mootools/mootools-core.git' },
  { path: 'restfulx_framework.git', git: 'git@github.com:dima/restfulx_framework.git' },
  { path: 'gitx.git', git: 'git@github.com:pieter/gitx.git' },
  { path: 'asi-http-request.git', git: 'git@github.com:pokeb/asi-http-request.git' },
  { path: 'git.git', git: 'git@github.com:git/git.git' },
  { path: 'raphael.git', git: 'git@github.com:DmitryBaranovskiy/raphael.git' },
  { path: 'cappuccino.git', git: 'git@github.com:cappuccino/cappuccino.git' },
  { path: 'turn.git', git: 'git@github.com:TwP/turn.git' },
  { path: 'rhodes.git', git: 'git@github.com:rhomobile/rhodes.git' },
  { path: 'webpy.git', git: 'git@github.com:webpy/webpy.git' },
  { path: 'cufon.git', git: 'git@github.com:sorccu/cufon.git' },
  { path: 'emacs-starter-kit.git', git: 'git@github.com:technomancy/emacs-starter-kit.git' },
  { path: 'yui3.git', git: 'git@github.com:yui/yui3.git' },
  { path: 'yajl.git', git: 'git@github.com:lloyd/yajl.git' },
  { path: 'sinatra.git', git: 'git@github.com:sinatra/sinatra.git' },
  { path: 'mongo.git', git: 'git@github.com:mongodb/mongo.git' },
  { path: 'rakudo.git', git: 'git@github.com:rakudo/rakudo.git' },
  { path: 'three20.git', git: 'git@github.com:facebook/three20.git' },
  { path: 'yaws.git', git: 'git@github.com:klacke/yaws.git' },
  { path: 'ack.git', git: 'git@github.com:petdance/ack.git' },
  { path: 'redis.git', git: 'git@github.com:antirez/redis.git' },
  { path: 'pinax.git', git: 'git@github.com:pinax/pinax.git' },
  { path: 'aquamacs-emacs.git', git: 'git@github.com:davidswelt/aquamacs-emacs.git' },
  { path: 'jquery.git', git: 'git@github.com:jquery/jquery.git' },
  { path: 'memcached.git', git: 'git@github.com:memcached/memcached.git' },
  { path: 'phonegap.git', git: 'git@github.com:phonegap/phonegap.git' },
  { path: 'ElementParser.git', git: 'git@github.com:Objective3/ElementParser.git' },
  { path: 'SimFinger.git', git: 'git@github.com:atebits/SimFinger.git' },
  { path: 'homebrew.git', git: 'git@github.com:mxcl/homebrew.git' },
  { path: 'node.git', git: 'git@github.com:joyent/node.git' },
  { path: 'voldemort.git', git: 'git@github.com:voldemort/voldemort.git' },
  { path: 'scalatra.git', git: 'git@github.com:scalatra/scalatra.git' },
  { path: 'GitSharp.git', git: 'git@github.com:henon/GitSharp.git' },
  { path: 'z.git', git: 'git@github.com:rupa/z.git' },
  { path: 'wax.git', git: 'git@github.com:probablycorey/wax.git' },
  { path: 'AppSales-Mobile.git', git: 'git@github.com:omz/AppSales-Mobile.git' },
  { path: 'greasemonkey.git', git: 'git@github.com:greasemonkey/greasemonkey.git' },
  { path: 'web-socket-js.git', git: 'git@github.com:gimite/web-socket-js.git' },
  { path: 'nginx_http_push_module.git', git: 'git@github.com:slact/nginx_http_push_module.git' },
  { path: 'Sparkle.git', git: 'git@github.com:andymatuschak/Sparkle.git' },
  { path: 'v8.git', git: 'git@github.com:v8/v8.git' },
  { path: 'rvm.git', git: 'git@github.com:wayneeseguin/rvm.git' },
  { path: 'cloud-crowd.git', git: 'git@github.com:documentcloud/cloud-crowd.git' },
  { path: 'tornado.git', git: 'git@github.com:facebook/tornado.git' },
  { path: 'bup.git', git: 'git@github.com:apenwarr/bup.git' },
  { path: 'underscore.git', git: 'git@github.com:documentcloud/underscore.git' },
  { path: 'projectplus.git', git: 'git@github.com:markhuot/projectplus.git' },
  { path: 'otp.git', git: 'git@github.com:erlang/otp.git' },
  { path: 'memprof.git', git: 'git@github.com:ice799/memprof.git' },
  { path: 'coffee-script.git', git: 'git@github.com:jashkenas/coffee-script.git' },
  { path: 'gordon.git', git: 'git@github.com:tobeytailor/gordon.git' },
  { path: 'hiphop-php.git', git: 'git@github.com:facebook/hiphop-php.git' },
  { path: 'symfony.git', git: 'git@github.com:symfony/symfony.git' },
  { path: 'phpbb.git', git: 'git@github.com:phpbb/phpbb.git' },
  { path: 'tinymce.git', git: 'git@github.com:tinymce/tinymce.git' },
  { path: 'ejabberd.git', git: 'git@github.com:processone/ejabberd.git' },
  { path: 'ruby.git', git: 'git@github.com:ruby/ruby.git' },
  { path: 'cakephp.git', git: 'git@github.com:cakephp/cakephp.git' },
  { path: 'clojure.git', git: 'git@github.com:clojure/clojure.git' },
  { path: 'buildbot.git', git: 'git@github.com:buildbot/buildbot.git' },
  { path: 'underscore.git', git: 'https://github.com/documentcloud/underscore.git' },
  { path: 'diaspora.git', git: 'https://github.com/diaspora/diaspora.git' },
  { path: 'brightbox/brightbox-cli.git', git: 'https://github.com/brightbox/brightbox-cli.git' },
  { path: 'brightbox/puppet.git',        git: 'https://github.com/brightbox/puppet.git' },
  { path: 'gitlab/gitlabhq.git',        git: 'https://github.com/gitlabhq/gitlabhq.git' },
  { path: 'gitlab/gitlab-ci.git',       git: 'https://github.com/gitlabhq/gitlab-ci.git' },
  { path: 'gitlab/gitlab-recipes.git', git: 'https://github.com/gitlabhq/gitlab-recipes.git' },
]

projects.each do |project|
  project_path = File.join(root, project[:path])

  if File.exists?(project_path)
    print '-'
    next
  end

  if system("/home/git/gitlab-shell/bin/gitlab-projects import-project #{project[:path]} #{project[:git]}")
    print '.'
  else
    print 'F'
  end
end

puts "OK".green

