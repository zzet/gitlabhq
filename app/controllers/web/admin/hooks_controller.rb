class Web::Admin::HooksController < Web::Admin::ApplicationController
  def index
    @hooks = SystemHook.all
    @hook = SystemHook.new
  end

  def create
    @hook = SystemHook.new(params[:hook])

    if @hook.save
      flash[:notice] = 'Hook was successfully created.'
    else
      flash[:error] = 'Some errors while hook was created.'
    end
      redirect_to admin_hooks_path
  end

  def destroy
    @hook = SystemHook.find(params[:id])
    if @hook.destroy
      flash[:notice] = 'Hook was successfully destroyed.'
    else
      flash[:error] = 'Some errors while hook was destroy.'
    end
    redirect_to admin_hooks_path
  end


  def test
    @hook = SystemHook.find(params[:hook_id])
    data = {
      event_name: "project_create",
      name: "Ruby",
      path: "ruby",
      project_id: 1,
      owner_name: "Someone",
      owner_email: "example@gitlabhq.com"
    }

    @hook.execute(data)

    redirect_to :back
  end
end
