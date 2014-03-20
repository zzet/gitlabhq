module GroupsSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,          type: :integer
      indexes :name,        type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :path,        type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :description, type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :created_at,  type: :date

      indexes :name_sort,   type: :string, index: :not_analyzed
    end

    def as_indexed_json(options = {})
      as_json.merge({
        name_sort: name
      })
    end

    def self.search(query, page: 1, per: 20, options: {})

      page ||= 1

      if options[:in].blank?
        options[:in] = %w(name^2 path)
      else
        options[:in].push(%w(name^2 path) - options[:in])
      end

      query_hash = {
        query: {
          filtered: {
            query: {
              multi_match: {
                fields: options[:in],
                query: "#{query}",
                operator: :and
              }
            },
          },
        },
        size: per,
        from: per * (page.to_i - 1)
      }

      if query.blank?
        query_hash[:query][:filtered][:query] = { match_all: {}}
        query_hash[:track_scores] = true
      end

      if options[:gids]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          ids: {
            values: options[:gids]
          }
        }
      end

      query_hash[:sort] = [
        { name_sort: { order: :asc, mode: :min }},
        :_score
      ]

      if options[:highlight]
        query_hash[:highlight] = { fields: options[:in].inject({}) { |a, o| a[o.to_sym] = {} } }
      end

      self.__elasticsearch__.search(query_hash).records
    end
  end
end
