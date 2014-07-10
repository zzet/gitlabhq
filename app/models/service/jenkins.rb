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
#  recipients         :text
#  api_key            :string(255)
#

class Service::Jenkins < Service
  include Service::CiService

  default_title       'Jenkins CI'
  default_description 'Continuous integration server from Jenkins'
  service_name        'jenkins'

  has_one :configuration, as: :service, class_name: Service::Configuration::Jenkins

  has_many :builds,   class_name: CiBuild, as: :service

  def execute(data)
    return true unless configuration.present?
    return true if configuration.host.blank?
    return true unless data[:ref] =~ /heads/

    # Create build for push
    branches_regexp = configuration.branches_regexp
    branch_name = data[:ref].gsub("refs/heads/", "")
    user = User.find(data[:user_id])

    if branch_name.match(branches_regexp)

      build = builds.create(source_project: project, source_branch: branch_name, source_sha: data[:after], user: user)
      build.run

    else

      if configuration.merge_request_enabled
        # Update code for merge requests in project
        mrs = project.merge_requests.opened.by_branch(branch_name).all
        mrs.each do |merge_request|
          build_merge_request(merge_request, user)
        end
      end

      # Update code for merge requests to project from forks
      mrs = project.fork_merge_requests.opened.by_branch(branch_name).all
      mrs.each do |merge_request|
        if merge_request.source_project != merge_request.target_project
          project_service = merge_request.target_project.services.where(type: Service::Jenkins).first
          if project_service.present? && project_service.configuration.merge_request_enabled
            build_merge_request(merge_request, user, :fork)
          end
        end
      end

    end

  end

  def build_merge_request(merge_request, user, merge_request_type = :project)
    merge_request.check_if_can_be_merged
    if merge_request.can_be_merged?
      if merge_request.commits.any?
        attrs = {
          merge_request: merge_request,
          target_project: merge_request_type == :project ? project : merge_request.target_project,
          source_project: project,
          target_branch: merge_request.target_branch,
          source_branch: merge_request.source_branch,
          target_sha: merge_request.commits.last.parent_id,
          source_sha: merge_request.commits.first.id,
          user: user
        }
        build = builds.create(attrs)
        build.run
      end
    end
  end

  def can_test?
    false
  end
end
