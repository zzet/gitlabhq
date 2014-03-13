###* @jsx React.DOM ###
window.SubscriptionTargetTabs = React.createClass({
  #TODO FIXME убрать магические строки с названиями табов
  getInitialState: () ->
    tab: @selectTab(@props)
    teams_count: @props.teams?.count || 0
    groups_count: @props.groups?.count || 0
    projects_count: @props.projects?.count || 0
    users_count: @props.users?.count || 0

    teams_search_term: ''
    groups_search_term: ''
    projects_search_term: ''
    users_search_term: ''

  render: () ->
    cx = React.addons.classSet
    projectsClass = cx(
      'active': @selectedTab('projects')
      'hide': @emptyTab('projects')
    )
    projectsContentClass = cx(
      'hide': @emptyTab('projects') or not @selectedTab('projects')
    )

    groupsClass = cx(
      'active': @selectedTab('groups')
      'hide': @emptyTab('groups')
    )
    groupsContentClass = cx(
      'hide': @emptyTab('groups') or not @selectedTab('groups')
    )

    teamsClass = cx(
      'active': @selectedTab('teams')
      'hide': @emptyTab('teams')
    )
    teamsContentClass = cx(
      'hide': @emptyTab('teams') or not @selectedTab('teams')
    )

    usersClass = cx(
      'active': @selectedTab('users')
      'hide': @emptyTab('users')
    )
    usersContentClass = cx(
      'hide': @emptyTab('users') or not @selectedTab('users')
    )

    tabsClass = cx(
      'hide': @emptyTab('projects') and @emptyTab('groups') and @emptyTab('teams') and @emptyTab('users')
      'nav': true
      'nav-tabs': true
    )

    `<div>
      <ul className={tabsClass}>
        <li className={projectsClass}>
          <a href="#" onClick={this.projectsTab}>
            Projects
            <span className="badge">{this.state.projects_count}</span>
          </a>
        </li>
        <li className={groupsClass}>
          <a href="#" onClick={this.groupsTab}>
            Groups
            <span className="badge">{this.state.groups_count}</span>
          </a>
        </li>
        <li className={teamsClass}>
          <a href="#" onClick={this.teamsTab}>
            Teams
            <span className="badge">{this.state.teams_count}</span>
          </a>
        </li>
        <li className={usersClass}>
          <a href="#" onClick={this.usersTab}>
            Users
            <span className="badge">{this.state.users_count}</span>
          </a>
        </li>
      </ul>

      <div className={projectsContentClass}>
        <SubscriptionTargets tab={'projects'} count={this.state.projects_count}
          changeCount={this.changeProjectsCount}
          setTerm={this.setTerm.bind(null, 'projects_search_term')}
          optionsTitles={this.optionsTitles('projects')}
          optionsDescriptions={this.optionsDescriptions('projects')}
        />
      </div>

      <div className={groupsContentClass}>
        <SubscriptionTargets tab={'groups'} count={this.state.groups_count}
          changeCount={this.changeGroupsCount}
          setTerm={this.setTerm.bind(null, 'groups_search_term')}
          optionsTitles={this.optionsTitles('groups')}
          optionsDescriptions={this.optionsDescriptions('groups')}
        />
      </div>

      <div className={teamsContentClass}>
        <SubscriptionTargets tab={'teams'} count={this.state.teams_count}
          changeCount={this.changeTeamsCount}
          setTerm={this.setTerm.bind(null, 'teams_search_term')}
          optionsTitles={this.optionsTitles('teams')}
          optionsDescriptions={this.optionsDescriptions('teams')}
        />
      </div>

      <div className={usersContentClass}>
        <SubscriptionTargets tab={'users'} count={this.state.users_count}
          changeCount={this.changeUsersCount}
          setTerm={this.setTerm.bind(null, 'users_search_term')}
          optionsTitles={this.optionsTitles('users')}
          optionsDescriptions={this.optionsDescriptions('users')}
        />
      </div>
    </div>`

  projectsTab: (event) ->
    event.preventDefault()
    @setState(tab: 'projects')

  groupsTab: (event) ->
    event.preventDefault()
    @setState(tab: 'groups')

  teamsTab: (event) ->
    event.preventDefault()
    @setState(tab: 'teams')

  usersTab: (event) ->
    event.preventDefault()
    @setState(tab: 'users')

  changeProjectsCount: (count, tabUpdate = true) ->
    @setState(projects_count: count)
    @setState(tab: @selectTab(@state)) if tabUpdate

  changeTeamsCount: (count, tabUpdate = true) ->
    @setState(teams_count: count)
    @setState(tab: @selectTab(@state)) if tabUpdate

  changeGroupsCount: (count, tabUpdate = true) ->
    @setState(groups_count: count)
    @setState(tab: @selectTab(@state)) if tabUpdate

  changeUsersCount: (count, tabUpdate = true) ->
    @setState(users_count: count)
    @setState(tab: @selectTab(@state)) if tabUpdate

  setTerm: (target_term_key, term) ->
    stateUpdate = {}
    stateUpdate[target_term_key] = term
    @setState(stateUpdate)

  optionsTitles: (target) ->
    if @props[target] then @props[target].titles else {}

  optionsDescriptions: (target) ->
    if @props[target] then @props[target].descriptions else {}

  selectTab: (stateOrProps) ->
    if stateOrProps.projects_count
      'projects'
    else if stateOrProps.groups_count
      'groups'
    else if stateOrProps.teams_count
      'teams'
    else if stateOrProps.users_count
      'users'
    else
      ''

  selectedTab: (tab) -> @state.tab == tab

  emptyTab: (tab) ->
    @state["#{tab}_count"]== 0 and @state["#{tab}_search_term"] == ''
})
