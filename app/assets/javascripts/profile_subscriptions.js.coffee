#NOTE В связи с предстоящим редизайном страницы profiles:notifications:index данный код подразумевается быть удаленным и в данный момент несет оптимизационный характер (issue 29418)
class ProfileSubscriptions
  constructor: ->
    $('.tab-content').on 'ajax:success', 'a.js-unsubscribe', (event)->
      tableRow = $(this).closest('table tr')
      tableRow.remove()

    $('.tab-content').on 'ajax:success', 'a.js-projects-subscribe, a.js-projects-unsubscribe', (event)->
      link = $(this)
      if link.hasClass('js-projects-subscribe')
        replace_link = link.closest('td').find('.project-unsubscribe-link').html()
        link.replaceWith(replace_link)
      else
        replace_link = link.closest('td').find('.project-subscribe-link').html()
        link.replaceWith(replace_link)

@ProfileSubscriptions = ProfileSubscriptions
