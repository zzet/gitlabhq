require 'spec_helper'

# search GET    /search(.:format) search#show
describe Web::SearchesController, "routing" do
  it "to #show" do
    get("/search").should route_to('web/searches#show')
  end
end

# gitlab_api /api         Gitlab::API
#     resque /info/resque Resque::Server
#            /:path       Grack
describe "Mounted Apps", "routing" do
  it "to API" do
    get("/api").should be_routable
  end

  it "to Resque" do
    pending
    get("/info/resque").should be_routable
  end

  it "to Grack" do
    get("/gitlabhq.git").should be_routable
  end
end

#              help GET    /help(.:format)              helps#index
#  help_permissions GET    /help/permissions(.:format)  helps#permissions
#     help_workflow GET    /help/workflow(.:format)     helps#workflow
#          help_api GET    /help/api(.:format)          helps#api
#    help_web_hooks GET    /help/web_hooks(.:format)    helps#web_hooks
# help_system_hooks GET    /help/system_hooks(.:format) helps#system_hooks
#     help_markdown GET    /help/markdown(.:format)     helps#markdown
#          help_ssh GET    /help/ssh(.:format)          helps#ssh
describe Web::HelpsController, "routing" do
  it "to #index" do
    get("/help").should route_to('web/helps#index')
  end

  it "to #permissions" do
    get("/help/permissions").should route_to('web/helps#permissions')
  end

  it "to #workflow" do
    get("/help/workflow").should route_to('web/helps#workflow')
  end

  it "to #api" do
    get("/help/api").should route_to('web/helps#api')
  end

  it "to #web_hooks" do
    get("/help/web_hooks").should route_to('web/helps#web_hooks')
  end

  it "to #system_hooks" do
    get("/help/system_hooks").should route_to('web/helps#system_hooks')
  end

  it "to #markdown" do
    get("/help/markdown").should route_to('web/helps#markdown')
  end

  it "to #ssh" do
    get("/help/ssh").should route_to('web/helps#ssh')
  end
end

# errors_githost GET    /errors/githost(.:format) errors#githost
describe Web::ErrorsController, "routing" do
  it "to #githost" do
    get("/errors/githost").should route_to('web/errors#githost')
  end
end

#             profile_account GET    /profile/account(.:format)             profile#account
#             profile_history GET    /profile/history(.:format)             profile#history
#            profile_password PUT    /profile/password(.:format)            profile#password_update
#               profile_token GET    /profile/token(.:format)               profile#token
# profile_reset_private_token PUT    /profile/reset_private_token(.:format) profile#reset_private_token
#                     profile GET    /profile(.:format)                     profile#show
#              profile_design GET    /profile/design(.:format)              profile#design
#              profile_update PUT    /profile/update(.:format)              profile#update
describe Web::ProfilesController, "routing" do
  it "to #account" do
    get("/profile/account").should route_to('web/profiles#account')
  end

  it "to #history" do
    get("/profile/history").should route_to('web/profiles#history')
  end

  it "to #password_update" do
    put("/profile/password").should route_to('web/profiles#password_update')
  end

  it "to #token" do
    get("/profile/token").should route_to('web/profiles#token')
  end

  it "to #reset_private_token" do
    put("/profile/reset_private_token").should route_to('web/profiles#reset_private_token')
  end

  it "to #show" do
    get("/profile").should route_to('web/profiles#show')
  end

  it "to #design" do
    get("/profile/design").should route_to('web/profiles#design')
  end

  it "to #update" do
    put("/profile").should route_to('web/profiles#update')
  end
end

#     keys GET    /keys(.:format)          keys#index
#          POST   /keys(.:format)          keys#create
#  new_key GET    /keys/new(.:format)      keys#new
# edit_key GET    /keys/:id/edit(.:format) key#edit
#      key GET    /keys/:id(.:format)      keys#show
#          PUT    /keys/:id(.:format)      keys#update
#          DELETE /keys/:id(.:format)      keys#destroy
describe Web::Profiles::KeysController, "routing" do
  it "to #index" do
    get("/profile/keys").should route_to('web/profiles/keys#index')
  end

  it "to #create" do
    post("/profile/keys").should route_to('web/profiles/keys#create')
  end

  it "to #new" do
    get("/profile/keys/new").should route_to('web/profiles/keys#new')
  end

  it "to #edit" do
    get("/profile/keys/1/edit").should route_to('web/profiles/keys#edit', id: '1')
  end

  it "to #show" do
    get("/profile/keys/1").should route_to('web/profiles/keys#show', id: '1')
  end

  it "to #update" do
    put("/profile/keys/1").should route_to('web/profiles/keys#update', id: '1')
  end

  it "to #destroy" do
    delete("/profile/keys/1").should route_to('web/profiles/keys#destroy', id: '1')
  end
end

#                dashboard GET    /dashboard(.:format)                dashboard#index
#         dashboard_issues GET    /dashboard/issues(.:format)         dashboard#issues
# dashboard_merge_requests GET    /dashboard/merge_requests(.:format) dashboard#merge_requests
#                     root        /                                   dashboard#index
describe Web::DashboardController, "routing" do
  it "to #index" do
    get("/dashboard").should route_to('web/dashboard#index')
    get("/").should route_to('web/dashboard#index')
  end

  it "to #issues" do
    get("/dashboard/issues").should route_to('web/dashboard#issues')
  end

  it "to #merge_requests" do
    get("/dashboard/merge_requests").should route_to('web/dashboard#merge_requests')
  end
end

#        new_user_session GET    /users/sign_in(.:format)               devise/sessions#new
#            user_session POST   /users/sign_in(.:format)               devise/sessions#create
#    destroy_user_session DELETE /users/sign_out(.:format)              devise/sessions#destroy
# user_omniauth_authorize        /users/auth/:provider(.:format)        omniauth_callbacks#passthru
#  user_omniauth_callback        /users/auth/:action/callback(.:format) omniauth_callbacks#(?-mix:(?!))
#           user_password POST   /users/password(.:format)              devise/passwords#create
#       new_user_password GET    /users/password/new(.:format)          devise/passwords#new
#      edit_user_password GET    /users/password/edit(.:format)         devise/passwords#edit
#                         PUT    /users/password(.:format)              devise/passwords#update
describe "Authentication", "routing" do
  # pending
end
