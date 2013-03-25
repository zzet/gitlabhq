## GitLab: self hosted Git management software

![logo](https://raw.github.com/gitlabhq/gitlabhq/master/public/gitlab_logo.png)

### GitLab allows you to
 * keep your code secure on your own server
 * manage repositories, users and access permissions
 * communicate through issues, line-comments and wiki pages
 * perform code review with merge requests

### GitLab is

* powered by Ruby on Rails
* completely free and open source (MIT license)
* used by 10.000 organizations to keep their code secure

### Code status

* [![build status](http://ci.gitlab.org/projects/1/status?ref=master)](http://ci.gitlab.org/projects/1?ref=master) ci.gitlab.org (master branch)

* [![build status](https://secure.travis-ci.org/gitlabhq/gitlabhq.png)](https://travis-ci.org/gitlabhq/gitlabhq) travis-ci.org (master branch)

* [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.png)](https://codeclimate.com/github/gitlabhq/gitlabhq)

* [![Dependency Status](https://gemnasium.com/gitlabhq/gitlabhq.png)](https://gemnasium.com/gitlabhq/gitlabhq)

* [![Coverage Status](https://coveralls.io/repos/gitlabhq/gitlabhq/badge.png?branch=master)](https://coveralls.io/r/gitlabhq/gitlabhq)

### Resources

* GitLab.org community site: [Homepage](http://gitlab.org) [Screenshots](http://gitlab.org/screenshots/) [Blog](http://blog.gitlab.org/) [Demo](http://demo.gitlabhq.com/users/sign_in)

* GitLab.com commercial services: [Homepage](http://www.gitlab.com/) [GitLab Cloud](http://www.gitlab.com/cloud/) [Subscription](http://www.gitlab.com/subscription/) [Consultancy](http://www.gitlab.com/consultancy/) [Blog](http://blog.gitlab.com/)

* GitLab CI: [Readme](https://github.com/gitlabhq/gitlab-ci/blob/master/README.md) of the GitLab open-source continuous integration server

### Requirements

* Ubuntu/Debian**
* ruby 1.9.3
* MySQL
* git
* gitlab-shell
* redis

** More details are in the [requirements doc](https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/requirements.md)

### Installation

#### For production

Follow the installation guide for production server.

* [Installation guide for latest stable release (5.0)](https://github.com/gitlabhq/gitlabhq/blob/5-0-stable/doc/install/installation.md) - **Recommended**

* [Installation guide for the current master branch (5.1)](https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md)

#### For development

If you want to contribute, please first read our [Contributing Guidelines](https://github.com/gitlabhq/gitlabhq/blob/master/CONTRIBUTING.md) and then we suggest you to use the Vagrant virtual machine project to get an environment working sandboxed and with all dependencies.

* [Vagrant virtual machine](https://github.com/gitlabhq/gitlab-vagrant-vm)

#### Unsupported installation methods

* [GitLab recipes](https://github.com/gitlabhq/gitlab-recipes) for setup on different platforms

* [Unofficial installation guides](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Unofficial-Installation-Guides)



### Starting

1. The Installation guide contains instructions to download an init script and run that on boot. With the init script you can also start GitLab

        sudo service gitlab start

  or

        sudo /etc/init.d/gitlab restart

2. Start it with [Foreman](https://github.com/ddollar/foreman) in development mode

        bundle exec foreman start -p 3000

 or start it manually

        bundle exec rails s
        bundle exec rake sidekiq:start

### Running the tests

* Seed the database

        bundle exec rake db:setup RAILS_ENV=test
        bundle exec rake db:seed_fu RAILS_ENV=test

* Run all tests

        bundle exec rake gitlab:test

* Rspec unit and functional tests

        bundle exec rake spec

* Spinach integration tests

        bundle exec rake spinach

### Getting help

* [Troubleshooting guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide)

* [Support forum](https://groups.google.com/forum/#!forum/gitlabhq)

* [Feedback and suggestions forum](http://gitlab.uservoice.com/forums/176466-general)

* [Support subscription](http://www.gitlab.com/subscription/)

* [Consultancy](http://www.gitlab.com/consultancy/)

### New versions and upgrading

Each month on the 22th a new version is released together with an upgrade guide.

* [Upgrade guides](https://github.com/gitlabhq/gitlabhq/wiki)

* [Changelog](https://github.com/gitlabhq/gitlabhq/blob/master/CHANGELOG)

* [Roadmap](https://github.com/gitlabhq/gitlabhq/blob/master/ROADMAP.md)

### GitLab interfaces

* [GitLab API](https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/README.md)

* [Rake tasks](https://github.com/gitlabhq/gitlabhq/tree/master/doc/raketasks)

* [Directory structure](https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/structure.md)

* [Databases](https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/databases.md)

### Getting in touch

* [Contributing guide](https://github.com/gitlabhq/gitlabhq/blob/master/CONTRIBUTING.md)

* [Core team](https://github.com/gitlabhq?tab=members)

* [Contributors](https://github.com/gitlabhq/gitlabhq/graphs/contributors)

* [Leader](https://github.com/randx)

* [Contact page](http://gitlab.org/contact/)
