class JenkinsBuild
  constructor: ->
    build_status_additional = $('.build_status_additional')

    build_status_additional.popover({
      html : true,
      placement: 'left',
      content: ()->
        $(this).find('.build-info').html()
    })
    .click((e)-> e.preventDefault())

    $(".commit").on "ajax:success", '.popover form', (e, data, status, xhr) ->
      $(e.target).parents('.commit').find('.build_status').empty().append(data)
      build_status_additional.popover('hide')

@JenkinsBuild = JenkinsBuild
