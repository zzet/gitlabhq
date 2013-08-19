class Projects::TokensController < Profiles::ApplicationController
  def index
    @tokens = FileToken.where(user_id: current_user)
  end

  def destroy
    token = FileToken.where(user_id: current_user).find(params[:id])
    token.destroy
    redirect_to profile_tokens_path
  end
end
