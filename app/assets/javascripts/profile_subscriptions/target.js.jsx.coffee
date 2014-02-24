###* @jsx React.DOM ###
window.ProfileSubscriptionsTarget = React.createClass({
  render: () ->
    `<tr>
      <td><input type="checkbox" checked={this.props.checked} onClick={this.toggle}/></td>

      <td>
        <a href={this.props.target.link}>{this.nameWithNamespace()}</a>
        <div className={this.optionsClasses()}>
          <ProfileSubscriptionsOptions
            target={this.props.target}
            toggle={this.props.toggleOption}
            toggleAll={this.props.toggleAllOption}
            optionsTitles={this.props.optionsTitles}
          />

          <button type="button" className="btn btn-primary btn-tiny settings-save-btn"
            onClick={this.props.save.bind(null, this.props.target)}>Save</button>
        </div>
      </td>

      <td className='options'>{this.checkedOptions().join(', ')}</td>

      <td className={this.props.adjacentClass}>
        {_.keys(this.props.target.adjacent).map(function(adjacentTarget) {
          return(
          <div className="adjacent" onClick={this.adjacentToggle.bind(this, adjacentTarget)}>
            <i className={this.adjacentClassIcon(this.props.target.adjacent[adjacentTarget])}/>
            <span>{_.humanize(adjacentTarget)}</span>
          </div>);
        }.bind(this))}
      </td>

      <td className='actions'>
        <i className="icon-th-list" onClick={this.toggleOptionsVisibility}></i>
        <button type="button" className="btn btn-default btn-tiny"
          onClick={this.props.unsubscribe.bind(null, this.props.target)}>Unsubscribe</button>
      </td>
    </tr>`

  adjacentToggle: (adjacentTarget, event) ->
    checked = @props.target.adjacent[adjacentTarget]
    data = {
      target: adjacentTarget
      namespace_id: @props.target.id
      namespace_type: @props.targetModel
    }

    if checked
      Api.subscriptions.deleteAdjacent(data, (response) =>
        @props.target.adjacent[adjacentTarget] = false
        @props.updateTargets()
      )
    else
      Api.subscriptions.createAdjacent(data, (response) =>
        @props.target.adjacent[adjacentTarget] = true
        @props.updateTargets()
      )

  checkedOptions: () ->
    options = _(@props.target.options).keys().filter((option) =>
      @props.target.options[option]
    )

    _.map(options, (option) => @props.optionsTitles[option])

  optionsClasses: () ->
    React.addons.classSet({
      'target-options': true,
      'hide': not @props.target.optionsVisible,
    })

  adjacentClassIcon: (star) ->
    React.addons.classSet({
      'icon-star': star,
      'icon-star-empty': not star,
    })

  toggle: (event) ->
    @props.toggle(@props.target)

  toggleOptionsVisibility: (event) ->
    @props.toggleOptionsVisibility(@props.target)

  nameWithNamespace: () ->
    if @props.targetModel == 'User'
      @props.target.name
    else
      _.compact([@props.target.namespace, @props.target.name]).join('/')
})
