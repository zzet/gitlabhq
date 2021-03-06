class SidebarSort
  constructor: ->
    container = $('#projects')
    tabs = container.find('.project-sorting-tabs li')
    projectListContainer = container.find('.well-list')
    projectList = projectListContainer.find('li.project-row')

    tabs.find('a').click(() ->
      tabs.removeClass('active')
      $(@).parent().addClass('active')

      switch $(@).attr('href')
        when '#alphabetically'
          projectList = _.sortBy(projectList, (project) ->
            $(project).find('.project-name').text().trim().toLowerCase()
          )
        when '#by_last_push'
          projectList = _.sortBy(projectList, (project) ->
            last_push_at = $(project).find('.js-last-push').data('sort-by-last-push')
            new Date(last_push_at || 0)
          ).reverse()

      projectListContainer.remove('li.project-row')
      projectListContainer.prepend(projectList)
    )

@SidebarSort = SidebarSort
