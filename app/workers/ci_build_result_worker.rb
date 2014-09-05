class CiBuildResultWorker
  @queue = :build_result

  def self.perform(data)
    source_build = CiBuild.find(data["buildId"])
    source_build.update_attributes(data: data)

    parser = Gitlab::Ci::Jenkins.new(data)
    parser.parse

    fill_build_data(source_build, parser)

    builds = CiBuild.where(source_sha: parser.commits,
                           source_project_id: source_build.source_project_id).
                           where.not(id: source_build.id)

    builds.find_each do |build|
      unless build.merge_request_build?
        if build.source_sha != parser.last_sha
          build.to_skipped
        else
          fill_build_data(build, parser, data)
        end
      end
    end
  end

  def self.fill_build_data(build, parser, data = nil)
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

    build.data     = data if data
    build.trace    = parser.build_log
    build.coverage = parser.coverage if parser.coverage.present?
    build.build_time = parser.build_time
    build.duration = parser.duration

    build.skipped_count = parser.test_result['skipped']
    build.failed_count = parser.test_result['failed']
    build.total_count = parser.test_result['total']

    build.save
  end
end
