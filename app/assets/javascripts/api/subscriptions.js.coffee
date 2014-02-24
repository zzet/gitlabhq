@ApiSubscriptions =
  projects_path: "/api/:version/subscriptions/targets"
  create_path: "/api/:version/subscriptions"
  destroy_path: "/api/:version/subscriptions/:type/:id"
  options_update_path: "/api/:version/subscriptions/options"
  to_all: "/api/:version/subscriptions/to_all"
  from_all: "/api/:version/subscriptions/from_all"
  adjacent: "/api/:version/subscriptions/adjacent"

  targets: (type, page = 1, perPage = 20, term = null) ->
    url = Api.buildUrl(@projects_path)
    $.get(url, {
      type: type,
      page: page,
      per_page: perPage,
      private_token: gon.api_token
      search: term
    })

  create: (type, id, callback) ->
    url = Api.buildUrl(@create_path)
    $.post(url, {target: {type: type, id: id}, private_token: gon.api_token}, callback)

  destroy: (type, id, callback) ->
    url = Api.buildUrl(@destroy_path)
    url = url.replace(':type', _.capitalize(type)).replace(':id', id)
    $.delete(url, {target: {type: type, id: id}, private_token: gon.api_token}, callback)

  optionsUpdate: (targets, type, options, callback) ->
    if _.isArray(targets)
      targets = _.map(targets, (target) -> target.id)

    url = Api.buildUrl(@options_update_path)
    data = {
      options: options
      targets: targets
      type: type
      private_token: gon.api_token
    }
    $.patch(url, data, callback)

  toAll: (type, callback) ->
    url = Api.buildUrl(@to_all)
    $.post(url, {subscription_type: type, private_token: gon.api_token}, callback)

  fromAll: (type, callback)->
    url = Api.buildUrl(@from_all)
    $.post(url, {subscription_type: type, private_token: gon.api_token}, callback)

  createAdjacent: (data, callback) ->
    url = Api.buildUrl(@adjacent)
    data['private_token'] = gon.api_token
    $.post(url, data, callback)

  deleteAdjacent: (data, callback) ->
    url = Api.buildUrl(@adjacent)
    data['private_token'] = gon.api_token
    $.delete(url, data, callback)
