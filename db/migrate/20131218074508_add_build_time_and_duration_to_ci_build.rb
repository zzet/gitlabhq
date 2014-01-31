class AddBuildTimeAndDurationToCiBuild < ActiveRecord::Migration
  def change
    add_column :ci_builds, :build_time, :datetime
    add_column :ci_builds, :duration, :time
  end
end
