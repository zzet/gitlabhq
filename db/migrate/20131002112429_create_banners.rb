class CreateBanners < ActiveRecord::Migration
  def change
    create_table :banners do |t|
      t.string :title
      t.text :description
      t.string :category
      t.string :state
      t.datetime :start_date
      t.datetime :end_date
      t.integer :author_id
      t.integer :entity_id
      t.string :entity_type

      t.timestamps
    end
  end
end
