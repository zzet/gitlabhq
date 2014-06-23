$ ->
  new Dispatcher()

class Dispatcher
  constructor: () ->
    @initSearch()
    new SearchResultHighlight() if $('body').attr('data-page') == "search:show"
    @initHighlight()
    @initPageScripts()

  initPageScripts: ->
    page = $('body').attr('data-page')
    project_id = $('body').attr('data-project-id')

    unless page
      return false

    path = page.split(':')

    switch page
      when 'projects:issues:index'
        Issues.init()
      when 'projects:issues:show'
        new Issue()
      when 'projects:milestones:show'
        new Milestone()
      when 'projects:issues:new', 'projects:merge_requests:new'
        GitLab.GfmAutoComplete.setup()
      when 'dashboard:show'
        new Dashboard()
        new Activities()
        new DashboardTooltips()
        new SidebarSort()
        new Events()
      when 'projects:commit:show'
        new Commit()
      when 'projects:compare:show', 'projects:compare:index'
        new Compare()
      when 'projects:commits:show', 'projects:merge_requests:index', 'projects:merge_requests:show'
        new JenkinsBuild()
      when 'groups:show'
        new Activities()
        new DashboardTooltips()
        new SidebarFilter()
        new SidebarSort()
        new SidebarTabs('groups')
        new Events('Group')
      when 'projects:show'
        new Activities()
        new SidebarFilter()
        new SidebarTabs('projects')
        new Events('Project')
      when 'teams:show'
        new Activities()
        new DashboardTooltips()
        new SidebarFilter()
        new SidebarSort()
        new SidebarTabs('teams')
        new Events('Team')
      when 'projects:new', 'projects:edit'
        new Project()
      when 'projects:teams:members:index'
        new TeamMembers()
      when 'projects:team_members:index'
        new SidebarTabs('project_team_members')
      when 'groups:members'
        new GroupMembers()
      when 'projects:tree:show'
        new TreeView()
      when 'projects:blob:show'
        new BlobView()
      when 'users:show'
        new Activities()
        new DashboardTooltips()
        new SidebarFilter()
        new SidebarTabs('users')
        new Events('User')
      when 'profiles:subscriptions:index'
        new ProfileSubscriptions()

    switch path.first()
      when 'admin' then new Admin()
      when 'projects'
        new Wikis() if path[1] == 'wikis'


  initSearch: ->
    opts = $('.search-autocomplete-opts')
    path = opts.data('autocomplete-path')
    project_id = opts.data('autocomplete-project-id')
    project_ref = opts.data('autocomplete-project-ref')

    new SearchAutocomplete(path, project_id, project_ref)

  initHighlight: ->
    $('.highlight pre code').each (i, e) ->
      $(e).html($.map($(e).html().split("\n"), (line, i) ->
        "<span class='line' id='LC" + (i + 1) + "'>" + line + "</span>"
      ).join("\n"))
      hljs.highlightBlock(e)
