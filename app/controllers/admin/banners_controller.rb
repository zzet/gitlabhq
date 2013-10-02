class Admin::BannersController < Admin::ApplicationController
  def index
    @banners = Banner.scoped
  end

  def new
    @banner = Banner.new
  end

  def edit
    @banner = Banner.find(params[:id])
  end

  def create
    @banner = Banner.new(params[:banner])
    @banner.author = current_user

    if @banner.save

    else

    end
    redirect_to admin_banners_path
  end

  def destroy
    @banner = Banner.find(params[:id])
    if @banner.destroy

    else

    end
    redirect_to admin_banners_path
  end

  def update
    @banner = Banner.find(params[:id])
    if @banner.update_attributes(params[:banner])

    else

    end
    redirect_to admin_banners_path
  end
end
