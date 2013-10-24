window.userPage = ->
  Pager.init 20, true

reloadActivities = ->
  $(".content_list").html ''
  Pager.init 20, true
