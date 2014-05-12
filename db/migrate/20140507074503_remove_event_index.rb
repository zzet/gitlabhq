class RemoveEventIndex < ActiveRecord::Migration
  def up
    remove_index :events, name: 'for_main_dashboard_index'
    add_index(:events, :created_at, order: {created_at: :desc})
  end

  def down
    add_index(:events, [:target_type, :target_id, :first_domain_type,
                        :first_domain_id, :second_domain_type, :second_domain_id],
              name: 'for_main_dashboard_index',
              order: {created_at: :desc},
              where: 'parent_event_id is NULL')
    remove_index(:events, column: :created_at)
  end
end
