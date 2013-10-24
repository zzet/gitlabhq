class AddServicePatternIdToService < ActiveRecord::Migration
  def change
    add_column :services, :service_pattern_id, :integer
    add_column :services, :public_state, :string
    add_column :services, :active_state, :string
    add_column :services, :description, :text
    change_column :services, :project_id, :integer, null: true
  end
end
