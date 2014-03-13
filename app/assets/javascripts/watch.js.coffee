$ ->
  $('.watch-button').click ->
    $watch_button = $(this)
    type = $watch_button.attr('data-entity-type')
    id = $watch_button.attr('data-entity-id')

    if $watch_button.hasClass('watched')
      Api.subscriptions.destroy(type, id, () ->
        $watch_button.removeClass('watched')
          .find('i').removeClass('icon-eye-open').addClass('icon-eye-close').end()
          .attr('data-original-title', 'Watch')
          .find('span').text('Watch').end()

      )
    else
      Api.subscriptions.create(type, id, (data) ->
        $watch_button.addClass('watched')
          .find('i').removeClass('icon-eye-close').addClass('icon-eye-open').end()
          .find('span').text('Unwatch').end()
      )

