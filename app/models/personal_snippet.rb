# == Schema Information
#
# Table name: snippets
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  author_id  :integer          not null
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#  file_name  :string(255)
#  expires_at :datetime
#  private    :boolean          default(TRUE), not null
#  type       :string(255)
#

class PersonalSnippet < Snippet
  include Watchable

  source watchable_name do
    from :create,   to: :created
    from :update,   to: :updated
    from :destroy,  to: :deleted
  end
end
