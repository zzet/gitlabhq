# Controller for viewing a repository's file structure
class Projects::TreeController < Projects::BaseTreeController
  def show
    return not_found! if tree.entries.empty?

    @file_token = FileToken.for_project(@project).find_by_file(@path)

    respond_to do |format|
      format.html
      # Disable cache so browser history works
      format.js { no_cache_headers }
    end
  end
end
