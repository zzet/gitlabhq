class AddSummaryDiffToEventSummary < ActiveRecord::Migration
  def change
    add_column :event_summaries, :summary_diff, :boolean, null: false, default: true
  end
end
