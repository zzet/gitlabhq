class Compare
  constructor: ->
    $("#from, #to").autocomplete({
      source: gon.available_tags,
      minLength: 1
    })

    @comparePathContainer = $('#comparePathContainer')
    @pathSelectInput = $("#paths")

    @pathSelectInput.autocomplete({
      source: gon.available_paths,
      minLength: 1,
      select: (event, ui) =>
        @addPath(ui.item.value)
        event.preventDefault()
    })
    .keypress((event) =>
      if event.which == 13 and @pathSelectInput.val()
        event.preventDefault()
        event.stopPropagation()
        @pathSelectInput.autocomplete("close");
        @addPath()
    )

    @comparePathContainer.on('click', '.icon-remove', () ->
      $(@).parent().remove()
    )

    disableButtonIfEmptyField('#to', '.commits-compare-btn');

  addPath: (pathValue)->
    pathValue ||= @pathSelectInput.val()
    input = $(gon.path_template)
    input.find('input').val(pathValue)
    @comparePathContainer.append(input)
    @pathSelectInput.val('')

@Compare = Compare
