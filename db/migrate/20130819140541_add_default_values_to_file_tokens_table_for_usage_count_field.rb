class AddDefaultValuesToFileTokensTableForUsageCountField < ActiveRecord::Migration
  def change
    change_column :file_tokens, :usage_count, :integer, default: 0
  end
end
