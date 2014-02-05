$ ->
  groupFormatResult = (group) ->
    "<div class='group-result'>
       <div class='group-name'>#{group.name}</div>
       <div class='group-path'>#{group.path}</div>
     </div>"

  groupFormatSelection = (group) ->
    group.name

  $('.ajax-groups-select').each (i, select) ->
    $(select).select2
      placeholder: "Search for a group"
      multiple: $(select).hasClass('multiselect')
      minimumInputLength: 0
      query: (query) ->
        Api.groups query.term, (groups) ->
          data = { results: groups }
          query.callback(data)

      initSelection: (element, callback) ->
        id = $(element).val()
        if id isnt ""
          Api.group(id, callback)


      formatResult: groupFormatResult
      formatSelection: groupFormatSelection
      dropdownCssClass: "ajax-groups-dropdown"
      escapeMarkup: (m) -> # we do not want to escape markup since we are displaying html in results
        m
