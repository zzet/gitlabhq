module UsersSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,          type: :integer
      indexes :email,       type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :name,        type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :username,    type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :bio,         type: :string
      indexes :skype,       type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :linkedin,    type: :string
      indexes :twitter,     type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :state,       type: :string
      indexes :website_url, type: :string
      indexes :created_at,  type: :date
      indexes :admin,       type: :boolean

      indexes :name_sort,   type: :string, index: 'not_analyzed'
    end

    def as_indexed_json(options = {})
      as_json.merge({
        name_sort: name
      })
    end

    def self.search(query, page: 1, per: 20, options: {})

      page ||= 1

      if options[:in].blank?
        options[:in] = %w(name^3 username^2 email)
      else
        options[:in].push(%w(name^3 username^2 email) - options[:in])
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

      if options[:uids]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          ids: {
            values: options[:uids]
          }
        }
      end

      if options[:active]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          terms: {
            state: ["active"]
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
