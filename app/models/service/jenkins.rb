# == Schema Information
#
# Table name: services
#
#  id                 :integer          not null, primary key
#  type               :string(255)
#  title              :string(255)
#  project_id         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  state              :string(255)
#  service_pattern_id :integer
#  public_state       :string(255)
#  active_state       :string(255)
#  description        :text
#

class Service::Jenkins < Service
  default_title       'Jenkins CI'
  default_description 'Continuous integration server from Jenkins'
  service_name        'jenkins'

  has_one :configuration, as: :service, class_name: Service::Configuration::Jenkins

  has_many :builds,   class_name: CiBuild

  def execute(data)
    return true unless ref =~ /heads/

    # Create build for push
    branches = configuration.branches.split(",")
    branch_name = data[:ref].gsub("refs/heads/", "")
    user = User.find(data[:user_id])

    if branches.include?(branch_name)
      bild = builds.create(target_project: project, target_sha: data[:after], user: user)
      build.run
    end

    if configuration.merge_request_enabled
      mrs = project.merge_requests.opened.by_branch(branch_name).scoped
      mrs.each do |merge_request|
        merge_request.check_if_can_be_merged
        if merge_request.can_be_merged?
          attrs = {
            target_project: project,
            source_project: project,
            target_sha: merge_request.commits.last.parent_id,
            source_sha: merge_request.commits.first.id,
            user: user
          }
          build = builds.create(attrs)
          build.run
        end
      end
    end

    # Update code for merge requests in project
    mrs = project.fork_merge_requests.opened.by_branch(branch_name).scoped
    mrs.each do |merge_request|
      project_service = merge_request.target_project.services.where(type: Service::Jenkins).first
      if project_service.present? && project_service.configuration.merge_request_enabled
        merge_request.check_if_can_be_merged
        if merge_request.can_be_merged?
          attrs = {
            target_project: merge_request.target_project,
            source_project: project,
            target_sha: merge_request.commits.last.parent_id,
            source_sha: merge_request.commits.first.id,
            user: user
          }
          build = builds.create(attrs)
          build.run
        end
      end
    end

  end
end
