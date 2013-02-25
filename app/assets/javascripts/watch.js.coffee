$ ->
  $('.watch-button').click ->
    $(this).toggleClass('watched')
    if ($(this).hasClass('watched'))
      $(this).find('i').removeClass('icon-eye-close').addClass('icon-eye-open')
    else
      $(this).find('i').removeClass('icon-eye-open').addClass('icon-eye-close')

