@Api =
  users_path: "/api/:version/users.json"
  user_path: "/api/:version/users/:id.json"
  groups_path: "/api/:version/groups.json"
  assign_groups_path: "/api/:version/groups/to_assign.json"
  group_path: "/api/:version/groups/:id.json"
  teams_path: "/api/:version/teams.json"
  team_path: "/api/:version/teams/:id.json"
  projects_path: "/api/:version/projects.json"
  assign_projects_path: "/api/:version/projects/to_assign.json"
  project_path: "/api/:version/projects/:id.json"
  notes_path: "/api/:version/projects/:id/notes.json"
  namespaces_path: "/api/:version/namespaces.json"
  project_users_path: "/api/:version/projects/:id/users.json"

  subscriptions: ApiSubscriptions
  favourites: ApiFavourites

  # Get 20 (depends on api) recent notes
  # and sort the ascending from oldest to newest
  notes: (project_id, callback) ->
    url = Api.buildUrl(Api.notes_path)
    url = url.replace(':id', project_id)

    $.ajax(
      url: url,
      data:
        private_token: gon.api_token
        gfm: true
        recent: true
      dataType: "json"
    ).done (notes) ->
      notes.sort (a, b) ->
        return a.id - b.id
      callback(notes)

  user: (user_id, callback) ->
    url = Api.buildUrl(Api.user_path)
    url = url.replace(':id', user_id)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
      dataType: "json"
    ).done (user) ->
      callback(user)

  # Return users list. Filtered by query
  # Only active users retrieved
  users: (query, callback) ->
    url = Api.buildUrl(Api.users_path)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
        active: true
      dataType: "json"
    ).done (users) ->
      callback(users)

  # Return teams list. Filtered by query
  # Only known teams
  teams: (query, callback) ->
    url = Api.buildUrl(Api.teams_path)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
        active: true
      dataType: "json"
    ).done (teams) ->
      callback(teams)

  team: (team_id, callback) ->
    url = Api.buildUrl(Api.team_path)
    url = url.replace(':id', team_id)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
      dataType: "json"
    ).done (team) ->
      callback(team)


  # Return groups list. Filtered by query
  # Only known groups
  groups: (query, callback) ->
    url = Api.buildUrl(Api.assign_groups_path)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
        active: true
      dataType: "json"
    ).done (groups) ->
      callback(groups)

  group: (group_id, callback) ->
    url = Api.buildUrl(Api.group_path)
    url = url.replace(':id', group_id)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
      dataType: "json"
    ).done (group) ->
      callback(group)

  # Return projects list. Filtered by query
  # Only known projects
  projects: (query, callback) ->
    url = Api.buildUrl(Api.assign_projects_path)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
        active: true
      dataType: "json"
    ).done (projects) ->
      callback(projects)

  project: (project_id, callback) ->
    url = Api.buildUrl(Api.project_path)
    url = url.replace(':id', project_id)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
      dataType: "json"
    ).done (project) ->
      callback(project)

  # Return project users list. Filtered by query
  # Only active users retrieved
  projectUsers: (project_id, query, callback) ->
    url = Api.buildUrl(Api.project_users_path)
    url = url.replace(':id', project_id)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
        active: true
      dataType: "json"
    ).done (users) ->
      callback(users)

  # Return namespaces list. Filtered by query
  namespaces: (query, callback) ->
    url = Api.buildUrl(Api.namespaces_path)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
      dataType: "json"
    ).done (namespaces) ->
      callback(namespaces)

  buildUrl: (url) ->
    url = gon.relative_url_root + url if gon.relative_url_root?
    return url.replace(':version', gon.api_version)
