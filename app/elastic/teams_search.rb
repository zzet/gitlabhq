module TeamsSearch
  extend ActiveSupport::Concern

  included do
    include ApplicationSearch

    mappings do
      indexes :id,          type: :integer
      indexes :name,        type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :path,        type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :description, type: :string, index_options: 'offsets', search_analyzer: :search_analyzer, index_analyzer: :index_analyzer
      indexes :created_at,  type: :date

      indexes :members,     type: :nested
      indexes :owners,      type: :nested
      indexes :masters,     type: :nested
      indexes :developers,  type: :nested
      indexes :reporters,   type: :nested
      indexes :guests,      type: :nested
      indexes :projects,    type: :nested
      indexes :groups,      type: :nested

      indexes :name_sort,   type: :string, index: 'not_analyzed'
      indexes :created_at_sort, type: :string, index: 'not_analyzed'
      indexes :updated_at_sort, type: :string, index: 'not_analyzed'
    end

    def as_indexed_json(options = {})
      as_json(
        include: {
          members:    { only: :id },
          owners:     { only: :id },
          masters:    { only: :id },
          developers: { only: :id },
          reporters:  { only: :id },
          guests:     { only: :id },
          projects:   { only: :id },
          groups:     { only: :id },
        }
      ).merge({
        name_sort: name.downcase,
        updated_at_sort: updated_at,
        created_at_sort: created_at
      })
    end

    def self.search(query, page: 1, per: 20, options: {})

      page ||= 1

      if options[:in].blank?
        options[:in] = %w(name^10 path^5)
      else
        options[:in].push(%w(name^10 path^5) - options[:in])
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

      if !options[:member_id].blank?
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          nested: {
            path: :members,
            filter: {
              term: { "members.id" => options[:member_id] }
            }
          }
        }
      end

      if !options[:owner_id].blank?
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          nested: {
            path: :owners,
            filter: {
              term: { "owners.id" => options[:owner_id] }
            }
          }
        }
      end

      if !options[:group_id].blank?
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          nested: {
            path: :groups,
            filter: {
              term: { "groups.id" => options[:group_id] }
            }
          }
        }
      end

      if !options[:project_id].blank?
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          nested: {
            path: :projects,
            filter: {
              term: { "projects.id" => options[:project_id] }
            }
          }
        }
      end

      if options[:tids]
        query_hash[:query][:filtered][:filter] ||= { and: [] }
        query_hash[:query][:filtered][:filter][:and] << {
          ids: {
            values: options[:tids]
          }
        }
      end

      options[:order] = :default if options[:order].blank?
      order = case options[:order].to_sym
              when :newest
                { created_at_sort: { order: :asc, mode: :min } }
              when :oldest
                { created_at_sort: { order: :desc, mode: :min } }
              when :recently_updated
                { updated_at_sort: { order: :asc, mode: :min } }
              when :last_updated
                { updated_at_sort: { order: :desc, mode: :min } }
              else
                { name_sort: { order: :asc, mode: :min } }
              end


      query_hash[:sort] = [
        order,
        :_score
      ]

      if options[:highlight]
        query_hash[:highlight] = highlight_options(options[:in])
      end

      self.__elasticsearch__.search(query_hash)
    end
  end
end
