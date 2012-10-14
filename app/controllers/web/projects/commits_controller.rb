require "base64"

class Web::Projects::CommitsController < Web::Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def index
    @repo = @project.repo
    @limit, @offset = (params[:limit] || 40), (params[:offset] || 0)

    @commits = @project.commits(@ref, @path, @limit, @offset)
    @commits = CommitDecorator.decorate(@commits)

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.atom { render layout: false }
    end
  end

  def show
    result = CommitLoadContext.new(project, current_user, params).execute

    @commit = result[:commit]
    git_not_found! unless @commit

    @suppress_diff    = result[:suppress_diff]
    @note             = result[:note]
    @line_notes       = result[:line_notes]
    @notes_count      = result[:notes_count]
    @comments_allowed = true

    respond_to do |format|
      format.html do
        if result[:status] == :huge_commit
          render "huge_commit" and return
        end
      end

      format.patch
    end
  end

end
