class Projects::TokensController < Projects::ApplicationController
  include ExtractsPath

  def index
    @tokens = FileToken.where(project_id: @project)
  end

  def show
  end

  def create
    file_token = FileToken.new(project_id: @project.id, user_id: current_user.id, file: @path)
    file_token.generate_token!

    if file_token.save
      redirect_to project_raw_path(@project.path_with_namespace, @id, file_auth_token: file_token.token)
    else
      redirect_to project_raw_path(@project.path_with_namespace, @id)
    end
  end
end
