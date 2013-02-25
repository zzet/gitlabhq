$ ->
  $('.watch-button').click ->
    if ($(this).hasClass('watched'))
      $(this).removeClass('watched')
      $(this).find('i').removeClass('icon-eye-close').addClass('icon-eye-open')
    else
      $(this).addClass('watched')
      $(this).find('i').removeClass('icon-eye-open').addClass('icon-eye-close')

