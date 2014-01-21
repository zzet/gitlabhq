class Profiles::AccountsController < Profiles::ApplicationController
  def show
    @user = current_user
  end
end
