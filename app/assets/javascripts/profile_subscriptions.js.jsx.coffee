###* @jsx React.DOM ###
class ProfileSubscriptions
  constructor: ->
    React.renderComponent(
      `<SubscriptionTargetTabs
        projects={gon.projects}
        groups={gon.groups}
        teams={gon.teams}
        users={gon.users}/>`,
      document.getElementById('projects')
    )

    globalOptions = _.pick(gon.settings, 'own_changes', 'system_notifications', 'brave', 'adjacent_changes')
    React.renderComponent(
      `<SubscriptionGlobal options={globalOptions}
        adminOptions={gon.available_subscription_types}
        autoSubscriptions={gon.auto_subscriptions}/>`,
      document.getElementById('global')
    )


@ProfileSubscriptions = ProfileSubscriptions
