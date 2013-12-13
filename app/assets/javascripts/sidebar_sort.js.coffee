class SidebarSort
  constructor: ->
    container = $('#projects')
    tabs = container.find('.project-sorting-tabs li')
    projectListContainer = container.find('.well-list')
    projectList = projectListContainer.find('li')

    tabs.find('a').click(() ->
      tabs.removeClass('active')
      $(@).parent().addClass('active')

      switch $(@).attr('href')
        when '#alphabetically'
          projectList = _.sortBy(projectList, (project) ->
            $(project).find('.project-name').text()
          )
        when '#by_last_push'
          projectList = _.sortBy(projectList, (project) ->
            last_push_at = $(project).find('.js-last-push').data('sort-by-last-push')
            new Date(last_push_at || 0)
          ).reverse()

      projectListContainer.empty().append(projectList)
    )

@SidebarSort = SidebarSort
