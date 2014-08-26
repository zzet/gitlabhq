# == GitLab Shell mixin
#
# Provide a shortcut to Gitlab::Shell instance by gitlab_shell
#
module Gitlab
  module ShellAdapter
    def self.gitlab_shell
      Gitlab::Shell.new
    end

    def gitlab_shell
      Gitlab::Shell.new
    end
  end
end

