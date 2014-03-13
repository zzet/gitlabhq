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
    globalDescriptions = {
      brave: "By default for all members received notifications only
 about Pushes in projects, Merge requests and notes.
 Brave mode activate on all notification receiving.",
      adjacent_changes: 'Notifications about changes in related things.
 For ex.: You want to get notifications from all projects in group.'
    }

    React.renderComponent(
      `<SubscriptionGlobal options={globalOptions}
        descriptions={globalDescriptions}
        adminOptions={gon.available_subscription_types}
        autoSubscriptions={gon.auto_subscriptions}/>`,
      document.getElementById('global')
    )


@ProfileSubscriptions = ProfileSubscriptions
