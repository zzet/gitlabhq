class AddIndexToNoteForProjectIdWhereSystemFalse < ActiveRecord::Migration
  def up
    add_index(:notes, [:project_id],
              name: 'not_system_notes',
              where: 'system = false')

    remove_index(:events, name: 'for_main_dashboard_index')

    add_index(:events, [:target_type, :target_id,
                        :source_type, :source_id,
                        :first_domain_type, :first_domain_id,
                        :second_domain_type, :second_domain_id],
              name: 'for_main_dashboard_index',
              order: {created_at: :desc},
              where: 'parent_event_id is NULL')
  end

  def down
    remove_index(:events, name: 'for_main_dashboard_index')

    add_index(:events, [:target_type, :target_id, :first_domain_type,
                        :first_domain_id, :second_domain_type, :second_domain_id],
              name: 'for_main_dashboard_index',
              order: {created_at: :desc},
              where: 'parent_event_id is NULL')

    remove_index(:notes, name: 'not_system_notes')
  end
end
