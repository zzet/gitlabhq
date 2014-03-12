###* @jsx React.DOM ###
window.SubscriptionGlobal = React.createClass({
  componentDidUpdate: () ->
    $('.js-setting-description').tooltip({placement: 'bottom'})

  getInitialState: () ->
    tab: 'settings'
    options: @props.options
    autoSubscriptions: @props.autoSubscriptions

  render: () ->
    cx = React.addons.classSet
    settingsTabClass = cx('active': this.state.tab == 'settings')
    settingsContentClass = cx(
      'hide': this.state.tab != 'settings'
      'settings': true
    )

    globalTabClass = cx('active': this.state.tab == 'global')
    globalContentClass = cx(
      'hide': this.state.tab != 'global'
      'global': true
    )

    `<div>
      <ul className="nav nav-tabs">
        <li className={settingsTabClass}><a href="#" onClick={this.settingsTab}>Settings</a></li>
        <li className={globalTabClass}><a href="#" onClick={this.globalTab}>Global</a></li>
      </ul>

      <div className={settingsContentClass}>
        {_.keys(this.state.options).map(function(option) {
            return(
              <div>
                <button type="button" className="btn btn-small" onClick={this.toggleGlobalOption.bind(null, option)}>
                  <i className={this.optionClass(option)}></i>
                  <span>{_.humanize(option)}</span>
                </button>
                {this.description(option)}
              </div>
            )
        }.bind(this))}
      </div>

      <div className={globalContentClass}>
        <h4>Options for all projects</h4>
        <table>
          {this.props.adminOptions.map(function(option) {
            return <tr>
              <td>{_(option).capitalize()}</td>
              <td>
                <a className="new_items btn btn-small" onClick={this.createAutosubscribe.bind(null, option)}>New
                  <i className={this.autoSubscriptionsClass(option)}></i>
                </a>
              </td>
              <td>
                <a className="new_items btn btn-small" onClick={this.subscribe.bind(null, option)}>Subscribe</a>
              </td>
              <td>
                <a className="new_items btn btn-small" onClick={this.unSubscribe.bind(null, option)}>Unsubscribe</a>
              </td>
            </tr>
          }.bind(this))}
        </table>
      </div>
    </div>`

  autoSubscriptionsClass: (option) ->
    React.addons.classSet({
      "icon-star": @autoSubscriptionExists(option),
      "icon-star-empty": not @autoSubscriptionExists(option),
    })

  createAutosubscribe: (option, event) ->
    if @autoSubscriptionExists(option)
      asToDelete = _.select(@state.autoSubscriptions, (as) -> as.target == option).first()
      if asToDelete
        $.delete(Routes.profile_auto_subscription_path(asToDelete.id), {}, (response) =>
          autoSubscriptions = _.select(@state.autoSubscriptions, (as) -> as.id != asToDelete.id)
          @setState(autoSubscriptions: autoSubscriptions)
        )
    else
      $.post(Routes.profile_auto_subscriptions_path(), {auto_subscription: {target: option}}, (response) =>
        autoSubscriptions = @state.autoSubscriptions
        autoSubscriptions.push(response)
        @setState(autoSubscriptions: autoSubscriptions)
      )

  autoSubscriptionExists: (option) ->
    _.include(_.map(@state.autoSubscriptions, (as)-> as.target), option)

  subscribe: (option, event) ->
    question = "Would you like to subscribe to all #{option}s?"
    if confirm(question)
      Api.subscriptions.toAll(option, (response) =>
        $(document).trigger("#{option}s_subscribe")
      )

  unSubscribe: (option, event) ->
    question = "Would you like to unsubscribe from all #{option}s?"
    if confirm(question)
      Api.subscriptions.fromAll(option, (response) =>
        $(document).trigger("#{option}s_unsubscribe")
      )

  toggleGlobalOption: (option, event) ->
    options = @state.options
    options[option] = not options[option]
    @setState(options: options)

    $.patch(Routes.profile_notification_settings_path(), {
      notification_settings: @state.options
    })

  optionClass: (option) ->
    value = !!@state.options[option]
    React.addons.classSet('icon-star-empty': not value, 'icon-star': value)

  settingsTab: (event) ->
    event.preventDefault()
    @setState(tab: 'settings')

  globalTab: (event) ->
    event.preventDefault()
    @setState(tab: 'global')

  description: (option) ->
    if this.props.descriptions[option]
      `<i className="icon-question-sign js-setting-description" title={this.props.descriptions[option]}></i>`
    else
      ''
})
