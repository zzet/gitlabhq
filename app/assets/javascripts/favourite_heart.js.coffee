$ ->
  $('.heart-button').click ->
    $heart_button = $(this)
    type = $heart_button.attr('data-entity-type')
    id = $heart_button.attr('data-entity-id')

    if $heart_button.hasClass('hearted')
      Api.favourites.destroy(type, id, () ->
        $heart_button.removeClass('hearted')
          .find('i').removeClass('icon-heart').addClass('icon-heart-empty').end()
          .attr('data-original-title', 'Mark as favourite')
      )
    else
      Api.favourites.create(type, id, (data) ->
        $heart_button.addClass('hearted')
          .find('i').removeClass('icon-heart-empty').addClass('icon-heart').end()
          .attr('data-original-title', 'Remove from favourites')
      )

