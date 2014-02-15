module ApplicationSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    index_name [Rails.application.class.parent_name.downcase, self.name.downcase, Rails.env.to_s].join('-')

    settings \
      index: {
      query: {
        default_field: :name
      },
      analysis: {
        :analyzer => {
          :index_analyzer => {
            type: "custom",
            tokenizer: "ngram_tokenizer",
            filter: %w(lowercase asciifolding name_ngrams)
          },
          :search_analyzer => {
            type: "custom",
            tokenizer: "standard",
            filter: %w(lowercase asciifolding )
          }
        },
        tokenizer: {
          ngram_tokenizer: {
            type: "NGram",
            min_gram: 1,
            max_gram: 20,
            token_chars: %w(letter digit)
          }
        },
        filter: {
          name_ngrams: {
            type:     "NGram",
            max_gram: 20,
            min_gram: 1
          }
        }
      }
    }
  end
end
