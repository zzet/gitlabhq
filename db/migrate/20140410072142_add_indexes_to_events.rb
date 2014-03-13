class AddIndexesToEvents < ActiveRecord::Migration
  def change
    add_index(:events, [:target_type, :target_id, :first_domain_type,
                        :first_domain_id, :second_domain_type, :second_domain_id],
              name: 'for_main_dashboard_index',
              order: {created_at: :desc},
              where: 'parent_event_id is NULL')

    add_index(:events, [:target_type, :target_id])
  end
end
