class SidebarTabs
  constructor: (keyprefix) ->
    key = "#{keyprefix}_sidebar_tab"

    # store selection in cookie
    $('.js-sidebar-tabs a').on 'click', (e) ->
      $.cookie(key, $(e.target).attr('id'))

    # show tab from cookie
    sidebar_tab = $.cookie(key)
    $("#" + sidebar_tab).tab('show') if sidebar_tab

@SidebarTabs = SidebarTabs
