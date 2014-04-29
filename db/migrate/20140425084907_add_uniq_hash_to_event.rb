class AddUniqHashToEvent < ActiveRecord::Migration
  def change
    add_column :events, :uniq_hash, :string
    add_index :events, :uniq_hash
  end
end
