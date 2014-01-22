$ ->
  teamFormatResult = (team) ->
    "<div class='team-result'>
       <div class='team-name'>#{team.name}</div>
       <div class='team-path'>#{team.path}</div>
     </div>"

  teamFormatSelection = (team) ->
    team.name

  $('.ajax-teams-select').each (i, select) ->
    $(select).select2
      placeholder: "Search for a team"
      multiple: $(select).hasClass('multiselect')
      minimumInputLength: 0
      query: (query) ->
        Api.teams query.term, (teams) ->
          data = { results: teams }
          query.callback(data)

      initSelection: (element, callback) ->
        id = $(element).val()
        if id isnt ""
          Api.team(id, callback)


      formatResult: teamFormatResult
      formatSelection: teamFormatSelection
      dropdownCssClass: "ajax-teams-dropdown"
      escapeMarkup: (m) -> # we do not want to escape markup since we are displaying html in results
        m
