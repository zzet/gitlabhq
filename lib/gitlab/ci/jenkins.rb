module Gitlab
  class Ci::Jenkins
    attr_accessor :build_result_data

    def initialize(data)
      @build_result_data = data
    end

    def parse
      @build_result_data = YAML.load(@build_result_data) unless @build_result_data.is_a?(Hash)
    end

    def build_id
      @build_result_data["buildId"]
    end

    def md5
      @build_result_data["md5"]
    end

    def build_result
      @build_result_data["buildResult"]
    end

    def test_result
      res = @build_result_data["testResult"]
      res = if res.nil?
              {
                failed: 0,
                skipped: 0,
                total: 0
              }
            else
              {
                failed: res["failCount"],
                skipped: res["skipCount"],
                total: res["totalCount"]
              }
            end
    end

    def coverage
      @build_result_data["coverage"]
    end

    def build_log
      @build_result_data["consoleLog"]
    end

    def status
      build_result["result"].downcase
    end

    def last_sha
      commits.last
    end

    def commits
      @commits = build_result["changeSet"]["items"].map { |item| item["commitId"] }
      @commits = [build_result["actions"][2]["buildsByBranchName"]["detached"]["revision"]["SHA1"]] if @commits.blank?
      @commits
    end
  end
end
