###* @jsx React.DOM ###
window.ProfileSubscriptionsOptions = React.createClass({
  render: () ->
    `<div>
      <div className="target-option">
        <input type="checkbox" checked={this.allChecked()} onClick={this.toggleAll}/>
        <span>All</span>
      </div>
      {Object.keys(this.props.target.options).map(function(option, index) {
        return(
          <div className="target-option">
            <input type="checkbox" checked={this.props.target.options[option]}
              onClick={this.toggle.bind(null, option)}/>
              <span>{this.humanize(option)}</span>
          </div>)
      }.bind(this))}
    </div>`

  toggle: (option, event) ->
    @props.toggle(event, @props.target, option)

  toggleAll: (event) ->
    @props.toggleAll(event, @props.target)

  humanize: (option) ->
    @props.optionsTitles[option]

  allChecked: () ->
    for optionValue in _.values(@props.target.options)
      return false unless optionValue
    true
})
