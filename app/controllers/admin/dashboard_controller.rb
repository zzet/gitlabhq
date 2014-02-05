class Admin::DashboardController < Admin::ApplicationController
  def index
    @projects       = Project.order(created_at: :desc).limit(10)
    @users          = User.order(created_at: :desc).limit(10)
    @groups         = Group.order(created_at: :desc).limit(10)
    @teams          = Team.order(created_at: :desc).limit(10)

    @projects_count = Project.count
    @users_count    = User.count
    @groups_count   = Group.count
    @teams_count    = Team.count

    @forked_projects_count = ForkedProjectLink.count
    @issues_count         = Issue.count
    @merge_requests_count = MergeRequest.count
    @note_count           = Note.count
    @snippets_count       = Snippet.count
    @keys_count           = Key.count
    @milestones_count     = Milestone.count
    @file_tokens_count    = FileToken.count
  end
end
