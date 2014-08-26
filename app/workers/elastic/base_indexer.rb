class Elastic::BaseIndexer
  @queue = :elasticsearch

  Logger = Resque.logger.level == Logger::DEBUG ? Resque.logger : nil
  Client = Elasticsearch::Client.new(host: Gitlab.config.elasticsearch.host,
                                     port: Gitlab.config.elasticsearch.port,
                                     logger: Logger)

  def self.perform(operation, klass, record_id, options={})
    logger.debug [operation, "#{klass}##{record_id} #{options.inspect}"]

    cklass = klass.constantize

    case operation.to_s
    when /index|update/
      record = cklass.find(record_id)
      record.__elasticsearch__.client = Client
      # While we have not ability to set default options for index/update methods
      # https://github.com/elasticsearch/elasticsearch-rails/issues/66
      # TODO NOTE FIXME
      if Rails.env.to_sym == :test
        record.__elasticsearch__.__send__ "#{operation}_document", refresh: true
      else
        record.__elasticsearch__.__send__ "#{operation}_document"
      end
    when /delete/
      Client.delete index: cklass.index_name, type: cklass.document_type, id: record_id
    else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end
