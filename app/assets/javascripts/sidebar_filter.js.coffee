class SidebarFilter
  constructor: ->
    $(".js-sidebar-filter").keyup ->
      terms = $(this).val()
      uiBox = $(this).parents('.ui-box').first()
      if terms == "" || terms == undefined
        uiBox.find(".js-sidebar-list li").show()
      else
        uiBox.find(".js-sidebar-list li").each (index) ->
          name = $(this).find(".filter-title").text()

          if name.toLowerCase().search(terms.toLowerCase()) == -1
            $(this).hide()
          else
            $(this).show()

@SidebarFilter = SidebarFilter
