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

    def build_time
      time = build_result["timestamp"]
      (time) ? Time.at(time/1000).to_datetime : nil
    end

    def duration
      time = (build_result["duration"]) ? build_result["duration"] / 1000 : 0
      Time.at(time)
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
      begin
        return commits.last || build_result["actions"][3]["buildsByBranchName"]["detached"]["marked"]["branch"].first["SHA1"]
      rescue
        return nil
      end
    end

    def commits
      @commits = []
      begin
        @commits = build_result["changeSet"]["items"].map { |item| item["commitId"] }
        @commits << build_result["actions"][2]["buildsByBranchName"]["detached"]["revision"]["SHA1"] if build_result["actions"].first.blank?
      rescue
      end
      @commits
    end
  end
end
