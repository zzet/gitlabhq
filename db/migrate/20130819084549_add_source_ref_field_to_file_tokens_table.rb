class AddSourceRefFieldToFileTokensTable < ActiveRecord::Migration
  def change
    add_column :file_tokens, :source_ref, :string
  end
end
