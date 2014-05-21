class SearchAutocomplete
  PROJECT = 'Search in project'
  GLOBAL = 'Search global'

  constructor: (search_autocomplete_path, project_id, project_ref) ->
    project_id = '' unless project_id
    project_ref = '' unless project_ref
    query = "?project_id=" + project_id + "&project_ref=" + project_ref

    $("#search").autocomplete
      source: (request, response) ->
        $.get("#{search_autocomplete_path}#{query}&term=#{request.term}", (items) ->
          items.push({label: PROJECT}, {label: GLOBAL})
          response(items)
        )
      minLength: 1
      focus: (event, ui) ->
        event.preventDefault()

      select: (event, ui) ->
        if ui.item.url
          location.href = ui.item.url
        else
          searchForm = $(event.target).parents('form')
          if ui.item.label == GLOBAL
            searchForm.find('#project').remove()

          searchForm.submit()

@SearchAutocomplete = SearchAutocomplete
