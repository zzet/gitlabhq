class CiBuildResultWorker
  include Sidekiq::Worker
  include Gitlab::Identifier

  sidekiq_options queue: :build_result

  def perform(data)
    build = CiBuild.find(data["buildId"])
    build.data = data
    build.save
  end
end
