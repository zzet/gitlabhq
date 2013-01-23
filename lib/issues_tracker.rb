class IssuesTracker
  include Rails.application.routes.url_helpers

  def self.url_for_issue(project, issue_id)
    if project.issues_tracker == "gitlab"
      url = Rails.application.routes.url_helpers.project_issue_path project_id: project.id, id: issue_id
    else
      url = Settings[:issues_tracker][project.issues_tracker]["issues_url"]
      url.gsub(':id', issue_id.to_s).gsub(':project_id', project.id.to_s)
    end
  end

  def self.title_for_issue(project, issue_id)
    if issue = project.issues.where(id: issue_id).first
      issue.title
    else
      ""
    end
  end


  def self.issue_exists?(project, issue_id)
    if project.issues_tracker == "gitlab"
      project.issues.where(id: issue_id).first.present?
    else
      true
    end
  end
end
