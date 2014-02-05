class AddOriginalActionFieldToEventTable < ActiveRecord::Migration
  def change
    add_column :events, :system_action, :string
  end
end
