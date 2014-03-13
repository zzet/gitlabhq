###* @jsx React.DOM ###
window.ProfileSubscriptionsOptions = React.createClass({
  componentDidMount: () ->
    $('.js-target-option').tooltip({placement: 'right', container: 'body'})

  componentDidUpdate: () ->
    $('.js-target-option').tooltip({placement: 'right', container: 'body'})

  render: () ->
    `<div>
      <div className="target-option">
        <input type="checkbox" checked={this.allChecked()} onClick={this.toggleAll}/>
        <span>All</span>
      </div>
      {Object.keys(this.props.target.options).map(function(option, index) {
        var description = (this.props.optionsDescriptions) ? this.props.optionsDescriptions[option] : ''
        return(
          <div className="target-option">
            <input type="checkbox" checked={this.props.target.options[option]}
              onClick={this.toggle.bind(null, option)}/>
              <span className="js-target-option" title={description}>
                {this.props.optionsTitles[option]}
              </span>
          </div>)
      }.bind(this))}
    </div>`

  toggle: (option, event) ->
    @props.toggle(event, @props.target, option)

  toggleAll: (event) ->
    @props.toggleAll(event, @props.target)

  allChecked: () ->
    for optionValue in _.values(@props.target.options)
      return false unless optionValue
    true
})
