class Events
  constructor: () ->
    $("body").on('click', '.js-toggle-button', () ->
      childEventsContainer = $(this).parents('.js-toggle-container').find('.js-toggle-content')
      id = $(this).parents('.event-item').attr('rel')

      if childEventsContainer.is(':visible')
        $.get(Routes.events_path({dashboard: 'Project', parent_event_id: id}), (response) ->
          childEventsContainer.empty().append(response)
        )
    )

@Events = Events
