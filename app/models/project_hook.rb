# == Schema Information
#
# Table name: web_hooks
#
#  id         :integer          not null, primary key
#  url        :string(255)
#  project_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string(255)      default("ProjectHook")
#  service_id :integer
#

class ProjectHook < WebHook
  include Watchable

  belongs_to :project

  attr_accessible :project, :project_id

  source watchable_name do
    from :create, to: :created
    from :update, to: :updated
    from :destroy, to: :deleted
  end
end
