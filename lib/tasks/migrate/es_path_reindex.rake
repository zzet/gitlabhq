desc "es reindex path"
task es_reindex_path: :environment do
  puts "es reindex"

  client = Elasticsearch::Client.new log: false

  old_index_name = "repository-index-#{Rails.env}"
  index_name = "repository-index-#{Rails.env}-v2"

  Repository.__elasticsearch__.create_index! index: index_name

  r = client.search index: old_index_name, search_type: 'scan', scroll: '5m'

  # Call the `scroll` API until empty results are returned
  while r = client.scroll(scroll_id: r['_scroll_id'], scroll: '5m') and not r['hits']['hits'].empty? do
    puts "--- BATCH #{defined?($i) ? $i += 1 : $i = 1} -------------------------------------------------"

    bulk = { body: [] }


    r['hits']['hits'].each do |doc|
      bulk[:body].push({ index: {
        _index: index_name,
        _type: doc['_type'],
        _id: doc['_id'],
        data: doc['_source']
      }})
    end

    client.bulk(bulk)
  end

  client.indices.delete index: old_index_name
  client.indices.put_alias index: index_name, name: old_index_name
end
