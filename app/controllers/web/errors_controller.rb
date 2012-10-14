class Web::ErrorsController < Web::ApplicationController
  def githost
    render "errors/gitolite"
  end
end
