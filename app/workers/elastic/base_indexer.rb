class Elastic::BaseIndexer
  include Sidekiq::Worker
  sidekiq_options queue: 'elasticsearch', retry: false, backtrace: true

  Logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
  Client = Elasticsearch::Client.new host: (ENV['ELASTICSEARCH_URL'] || 'http://localhost:9200'), logger: Logger

  def perform(operation, klass, record_id, options={})
    logger.debug [operation, "#{klass}##{record_id} #{options.inspect}"]

    cklass = klass.constantize

    case operation.to_s
    when /index|update/
      record = cklass.find(record_id)
      record.__elasticsearch__.client = Client
      record.__elasticsearch__.__send__ "#{operation}_document"
    when /delete/
      Client.delete index: cklass.index_name, type: cklass.document_type, id: record_id
    else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end
