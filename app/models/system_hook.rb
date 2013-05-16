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

class SystemHook < WebHook
  include Watchable

  actions_to_watch [:created, :updated, :deleted]
  actions_sources [watchable_name]
  available_in_activity_feed false
end
