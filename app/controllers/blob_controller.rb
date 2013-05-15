# Controller for viewing a file's blame
class BlobController < ProjectResourceController
  include ExtractsPath

  skip_before_filter :authenticate_user!, :reject_blocked, :set_current_user_for_observers, :add_abilities, if: :file_auth_token_present?

  # Authorize
  before_filter :before_filters_for_users

  def show
    @blob = Gitlab::Git::Blob.new(@repository, @commit.id, @ref, @path)
  end

  protected

  def file_auth_token_present?
    params[:file_auth_token].present?
  end

  def before_filters_for_users
    if file_auth_token_present?
      token = params[:file_auth_token]
      available_token = FileToken.for_project(@project).find_by_file(@path)

      if available_token.blank? || available_token.token != token
        not_found!
      end
    else
      authorize_read_project!
      authorize_code_access!
    end

    require_non_empty_project
  end
end
