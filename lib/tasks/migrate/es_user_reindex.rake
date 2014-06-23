desc "es user reindex"
task es_reindex_user: :environment do
  #NOTE something strange happens with users
  User.__elasticsearch__.create_index! force: true
  User.import
end
