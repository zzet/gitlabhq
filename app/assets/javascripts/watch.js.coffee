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
    else
      $.post Routes.notifications_subscription_path(),
        entity:
          id: $watch_button.attr('data-entity-id')
          type: $watch_button.attr('data-entity-type')
        (data) -> 
          $watch_button.addClass('watched')
          $watch_button.find('i').removeClass('icon-eye-close').addClass('icon-eye-open')
          $watch_button.attr('data-original-title', 'Unwatch')

