###* @jsx React.DOM ###
window.SubscriptionTargets = React.createClass({
  getInitialState: () ->
    perPage = 20
    {
      targets: []
      checkedTargets: []
      page: 0
      perPage: perPage
      searchTerm: null
      totalCount: @props.count
    }

  componentWillMount: () ->
    @loadTargets(0) if @props.count

  componentDidMount: () ->
    $(document)
      .on("#{this.props.tab}_unsubscribe", () =>
        @props.changeCount(0)
        @setState(targets: [])
      )
      .on("#{this.props.tab}_subscribe", () =>
        @loadTargets(0)
      )

  componentWillUnmount: () ->
    $(document)
      .off("#{this.props.tab}_unsubscribe")
      .off("#{this.props.tab}_subscribe", )

  render: () ->
    cx = React.addons.classSet
    adjacentClass = cx('hide': this.props.tab != 'groups')
    targetsClass = cx('hide': @props.count == 0)
    nothingFoundClass = cx('hide': @props.count > 0)

    `<div>
      <form className="navbar-form navbar-left search" role="search">
        <div className="form-group">
          <input type="text" className="form-control" placeholder="Search"
            value={this.state.searchTerm} onChange={this.handleSearchChange}/>
        </div>
        <button type="submit" className="btn btn-default" onClick={this.search}>Submit</button>
      </form>

      <div className={targetsClass}>
        <table className='table'>
          <tbody>
            <tr>
              <th></th>
              <th>Name</th>
              <th>Options</th>
              <th className={adjacentClass}>Adjacent</th>
              <th>Actions</th>
            </tr>
            {this.state.targets.map(function(target) {
              return <ProfileSubscriptionsTarget
                target={target}
                checked={this.checked(target)}
                toggleOptionsVisibility={this.toggleOptionsVisibility}
                toggle={this.toggleTarget}
                toggleOption={this.toggleOption}
                tab={this.props.tab}
                targetModel={this.targetType()}
                toggleAllOption={this.toggleAllOptionHandler}
                save={this.save}
                unsubscribe={this.unsubscribe}
                adjacent={adjacentClass}
                updateTargets={this.updateTargets}
                optionsTitles={this.props.optionsTitles}
              />
            }.bind(this))}
          </tbody>
        </table>

        <Pagination page={this.state.page} pageCount={Math.ceil(this.props.count / this.state.perPage)}
          pageClickHanlder={this.pageClickHanlder} perPage={this.state.perPage}/>

        <SubscriptionMassOptions
          checkedTargets={this.state.checkedTargets}
          defaultOptions={this.defaultOptions()} type={this.targetType()}
          updateAfterMass={this.updateAfterMass}
          optionsTitles={this.props.optionsTitles}
          totalCount={this.state.totalCount}
          target={this.props.tab}
        />
      </div>

      <p className={nothingFoundClass}>Sorry, but nothing found.</p>
    </div>`

  search: (event) ->
    event.preventDefault()
    @props.setTerm(@state.searchTerm)
    @loadTargets(0, false)

  handleSearchChange: (event) ->
    @setState(searchTerm: event.target.value)

  save: (target, event) ->
    selectedOptions = @selectedOptions(target)

    Api.subscriptions.optionsUpdate([target], @targetType(), selectedOptions,
      (response) =>
        target.optionsVisible = false
        @setState(targets: @state.targets)
    )

  pageClickHanlder: (page, event) ->
    event.preventDefault()
    @setState(page: page)
    @loadTargets(page, false)

  unsubscribe: (target, event) ->
    Api.subscriptions.destroy(@targetType(), target.id, (response) =>
      withoutRemoved = _.filter(@state.targets, (t) -> t.id != target.id)
      @setState(targets: withoutRemoved)
    )

  toggleTarget: (target) ->
    checkedTargets = @state.checkedTargets

    if @checked(target)
      checkedTargets = _.without(checkedTargets, target)
    else
      checkedTargets.push(target)

    @setState(checkedTargets: checkedTargets)

  updateAfterMass: (checkedTargets, options) ->
    if checkedTargets == 'all'
      toUpdate = @state.targets
    else
      toUpdate = _.intersection(this.state.targets, checkedTargets)

    for target in toUpdate
      _.each(_.keys(target.options), (key) ->
        target.options[key] = _.include(options, key)
      )

    @setState(targets: @state.targets)

  checked: (target) ->
    _.include(@state.checkedTargets, target)

  toggleOptionsVisibility: (target) ->
    target.optionsVisible = not target.optionsVisible
    @setState(targets: @state.targets)

  toggleOption: (event, target, option) ->
    target.options[option] = not target.options[option]
    @setState(targets: @state.targets)

  updateTargets: () ->
    @setState(targets: @state.targets)

  toggleAllOptionHandler: (event, target) -> @toggleAllOption(target, event.target.checked)

  #private

  selectedOptions: (target) ->
    _.filter(_.keys(target.options), (key) -> target.options[key])

  targetType: () ->_.capitalize(_.rtrim(this.props.tab, 's'))

  toggleAllOption: (target, value) ->
    for k, v of target.options
      target.options[k] = value
    @setState(targets: @state.targets)

  loadTargets: (page, tabUpdate = true) ->
    Api.subscriptions.targets(@targetType(), page + 1, @state.perPage, @state.searchTerm).success((response) =>
      @props.changeCount(response.count, tabUpdate)
      @setState(targets: response.targets)
    )

  defaultOptions: () ->
    response = {}

    if _.any(@state.targets)
      options = _.clone(@state.targets?.first().options)
      _.each(_.keys(options), (optionKey) -> response[optionKey] = false)

    response
})
