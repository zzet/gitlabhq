class AddWikiIdToProjectForExternalWiki < ActiveRecord::Migration
  def change
    add_column :projects, :wiki_engine, :string
    add_column :projects, :wiki_external_id, :string
  end
end
