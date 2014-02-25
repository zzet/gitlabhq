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
      'active': @state.tab == 'projects'
      'hide': @state.projects_count == 0 and @state.projects_search_term == ''
    )
    projectsContentClass = cx(
      'hide': @state.tab != 'projects' or not @state.projects_count
    )

    groupsClass = cx(
      'active': @state.tab == 'groups'
      'hide': @state.groups_count == 0 and @state.groups_search_term == ''
    )
    groupsContentClass = cx(
      'hide': @state.tab != 'groups' or not @state.groups_count
    )

    teamsClass = cx(
      'active': @state.tab == 'teams'
      'hide': @state.teams_count == 0 and @state.teams_search_term == ''
    )
    teamsContentClass = cx(
      'hide': @state.tab != 'teams' or not @state.teams_count
    )

    usersClass = cx(
      'active': @state.tab == 'users'
      'hide': @state.users_count == 0 and @state.users_search_term == ''
    )
    usersContentClass = cx(
      'hide': @state.tab != 'users' or not @state.users_count
    )

    tabsClass = cx(
      'hide': not (@state.projects_count or @state.groups_count or @state.teams_count or @state.users_count)
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
        />
      </div>

      <div className={groupsContentClass}>
        <SubscriptionTargets tab={'groups'} count={this.state.groups_count}
          changeCount={this.changeGroupsCount}
          setTerm={this.setTerm.bind(null, 'groups_search_term')}
          optionsTitles={this.optionsTitles('groups')}
        />
      </div>

      <div className={teamsContentClass}>
        <SubscriptionTargets tab={'teams'} count={this.state.teams_count}
          changeCount={this.changeTeamsCount}
          setTerm={this.setTerm.bind(null, 'teams_search_term')}
          optionsTitles={this.optionsTitles('teams')}
        />
      </div>

      <div className={usersContentClass}>
        <SubscriptionTargets tab={'users'} count={this.state.users_count}
          changeCount={this.changeUsersCount}
          setTerm={this.setTerm.bind(null, 'users_search_term')}
          optionsTitles={this.optionsTitles('users')}
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
    @setState(target_term_key: term)

  optionsTitles: (target) ->
    if @props[target] then @props[target].titles else {}

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
})
