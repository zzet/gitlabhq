$ ->
  $('.watch-button').click ->
    $watch_button = $(this)
    if ($(this).hasClass('watched'))
      $.post Routes.notifications_subscription_path(),
        _method: 'delete'
        entity:
          id: $watch_button.attr('data-entity-id')
          type: $watch_button.attr('data-entity-type')
        (data) ->
          $watch_button.removeClass('watched')
          $watch_button.find('i').removeClass('icon-eye-open').addClass('icon-eye-close')
          $watch_button.attr('data-original-title', 'Watch')
          $watch_button.find('span').text('Watch')
    else
      $.ajax
        type: "POST",
        url: Routes.notifications_subscription_path(),
        data: 
          entity:
            id: $watch_button.attr('data-entity-id')
            type: $watch_button.attr('data-entity-type')
        complete: (xhr) ->
          if (xhr.readyState == 4 && xhr.status == 201)
            $watch_button.addClass('watched')
            $watch_button.find('i').removeClass('icon-eye-close').addClass('icon-eye-open')
            $watch_button.find('span').text('Unwatch')
