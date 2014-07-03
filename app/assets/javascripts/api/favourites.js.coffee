@ApiFavourites =
  create_path: "/api/:version/favourites"
  destroy_path: "/api/:version/favourites/:type/:id"

  create: (type, id, callback) ->
    url = Api.buildUrl(@create_path)
    $.post(url, {favourite: {type: type, id: id}, private_token: gon.api_token}, callback)

  destroy: (type, id, callback) ->
    url = Api.buildUrl(@destroy_path)
    url = url.replace(':type', _.capitalize(type)).replace(':id', id)
    $.delete(url, {favourite: {type: type, id: id}, private_token: gon.api_token}, callback)
