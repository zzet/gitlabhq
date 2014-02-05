$ ->
  projectFormatResult = (project) ->
    "<div class='project-result'>
       <div class='project-name'>#{project.name_with_namespace}</div>
       <div class='project-path'>#{project.path_with_namespace}</div>
     </div>"

  projectFormatSelection = (project) ->
    project.name

  $('.ajax-projects-select').each (i, select) ->
    $(select).select2
      placeholder: "Search for a project"
      multiple: $(select).hasClass('multiselect')
      minimumInputLength: 0
      query: (query) ->
        Api.projects query.term, (projects) ->
          data = { results: projects }
          query.callback(data)

      initSelection: (element, callback) ->
        id = $(element).val()
        if id isnt ""
          Api.project(id, callback)


      formatResult: projectFormatResult
      formatSelection: projectFormatSelection
      dropdownCssClass: "ajax-projects-dropdown"
      escapeMarkup: (m) -> # we do not want to escape markup since we are displaying html in results
        m
