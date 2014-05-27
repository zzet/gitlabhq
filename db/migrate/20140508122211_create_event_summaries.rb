class CreateEventSummaries < ActiveRecord::Migration
  def change
    create_table :event_summaries do |t|
      t.string :title
      t.text :description
      t.integer :user_id
      t.string :state
      t.string :period
      t.datetime :last_send_date

      t.timestamps
    end
  end
end
