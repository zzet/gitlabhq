window.userPage = ->
  Pager.init 20, true
  initSidebarTab()

reloadActivities = ->
  $(".content_list").html ''
  Pager.init 20, true
