class JenkinsBuildResultWorker
  include Sidekiq::Worker

  sidekiq_options queue: :jenkins_build_result

  def perform(build_id, token, result, *arg)
    build = CiBuild.find_by_id(build_id)

    if build.correct_token(token)

    end
  end
end
