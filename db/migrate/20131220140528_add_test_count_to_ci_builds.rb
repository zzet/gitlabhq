class AddTestCountToCiBuilds < ActiveRecord::Migration
  def change
    add_column :ci_builds, :skipped_count, :integer, default: 0
    add_column :ci_builds, :failed_count, :integer, default: 0
    add_column :ci_builds, :total_count, :integer, default: 0
  end
end
