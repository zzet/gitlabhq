class Admin::BackgroundJobsController < Admin::ApplicationController
  def show
    ps_output, _ = Gitlab::Popen.popen(%W(ps -U #{Settings.gitlab.user} -o pid,pcpu,pmem,stat,start,command))
    @resque = ps_output.split("\n").grep(/resque/)
  end
end
