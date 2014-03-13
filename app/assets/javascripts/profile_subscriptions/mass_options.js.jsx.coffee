###* @jsx React.DOM ###
window.SubscriptionMassOptions = React.createClass({
  getInitialState: () ->
    fakeTarget: {
      options: {}
    }

  componentWillReceiveProps: (nextProps) ->
    @setState(fakeTarget: {options: nextProps.defaultOptions})

  render: () ->
    cx = React.addons.classSet
    editAllTitleClass = cx('hide': _.any(this.props.checkedTargets))
    editSelectedClass = cx('hide': _.isEmpty(this.props.checkedTargets))
    setForMessage = "Set for all #{this.props.totalCount} #{this.props.target}"

    `<div className='mass'>
      <h4 className={editAllTitleClass}>{setForMessage}</h4>

      <div className={editSelectedClass}>
        <h4>Set for:</h4>
        <p>
          { this.props.checkedTargets.map(function(target) {
            return <span><a href={'/' + target.link}>{this.nameWithNamespace(target)}</a></span>
          }.bind(this))}
        </p>
      </div>

      <div className="alert alert-success">Saved</div>

      <ProfileSubscriptionsOptions
        target={this.state.fakeTarget}
        toggle={this.toggle}
        toggleAll={this.toggleAll}
        optionsTitles={this.props.optionsTitles}
        optionsDescriptions={this.props.optionsDescriptions}
      />

      <button type="button" className="btn btn-primary btn-tiny settings-save-btn"
        onClick={this.save}>Save</button>
    </div>`

  save: (event) ->
    alert = $(event.target).siblings('.alert')
    if _.any(this.props.checkedTargets)
      targets = this.props.checkedTargets
    else
      targets = 'all'

    options = @selectedOptions()

    Api.subscriptions.optionsUpdate(targets, @props.type, options, (response) =>
      alert.show().fadeOut(2000)
      @props.updateAfterMass(targets, options)
    )

  toggle: (event, target, option) ->
    target.options[option] = not target.options[option]
    @setState(fakeTarget: target)

  toggleAll: (event, target) ->
    for k, v of target.options
      target.options[k] = event.target.checked

    @setState(fakeTarget: target)

  nameWithNamespace: (target) ->
    _.compact([target.namespace, target.name]).join('/')

  selectedOptions: () ->
    _.filter(_.keys(@state.fakeTarget.options), (key) => @state.fakeTarget.options[key])
})
