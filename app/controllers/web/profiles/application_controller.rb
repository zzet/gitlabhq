class Web::Profiles::ApplicationController < Web::ApplicationController
  layout "profile"
  respond_to :js, :html
end
