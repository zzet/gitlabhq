# Controller for viewing a file's blame
class Projects::BlobController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    @blob = @repository.blob_at(@commit.id, @path)

    not_found! unless @blob

    @file_token = FileToken.for_project(@project).find_by_file(@path)
  end
end
