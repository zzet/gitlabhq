class CiBuildResultWorker
  include Sidekiq::Worker
  include Gitlab::Identifier

  sidekiq_options queue: :build_result

  def perform(data)
    source_build = CiBuild.find(data["buildId"])
    source_build.update_attributes(data: data)

    parser = Gitlab::Ci::Jenkins.new(data)
    parser.parse

    builds = CiBuild.where(target_sha: parser.commits)
    builds.each do |build|
      if build.target_sha != parser.last_sha
        build.to_skipped
      else
        case parser.status
        when "aborted"
          build.to_abort
        when "failure"
          build.to_fail
        when "not_built"
          build.to_skipped
        when "success"
          build.to_success
        when "unstable"
          build.to_unstable
        end

        build.coverage = parser.coverage if parser.coverage.present?
        build.trace = parser.build_log
        build.save
      end
    end
  end
end
