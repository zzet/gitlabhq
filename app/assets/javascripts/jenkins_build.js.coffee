class JenkinsBuild
  constructor: ->
    buildStatus = $('.build_status')

    buildStatus.popover({
      html : true,
      placement: 'left',
      content: ()->
        $(this).find('.build-info').html()
    })
    .click((e)-> e.preventDefault())

    $(".build").on "ajax:success", '.popover form', (e, data, status, xhr) ->
      $(e.target).parents('.commit').find('.build_status').empty().append(data)
      buildStatus.popover('hide')

@JenkinsBuild = JenkinsBuild
