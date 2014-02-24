###* @jsx React.DOM ###
window.Pagination = React.createClass({
  render: () ->
    cx = React.addons.classSet
    pagination = cx(
      'hide':  @props.pageCount < 2
      'pagination': true
    )

    `<ul className={pagination}>
      <li className={this.prevClass()}>
        <a href="#" onClick={this.props.pageClickHanlder.bind(null, 0)}>&laquo;</a>
      </li>
      {this.visiblePageLinks().map(function(index) {
        pageClass = cx({'active': index == this.props.page})
        return(
          <li className={pageClass}>
            <a href="#" onClick={this.props.pageClickHanlder.bind(null, index)}>{index + 1}</a>
          </li>
        )
      }.bind(this))}
      <li className={this.nextClass()}>
        <a href="#" onClick={this.props.pageClickHanlder.bind(null, this.props.pageCount - 1)}>&raquo;</a>
      </li>
    </ul>`

  prevClass: () ->
    React.addons.classSet({'hide': _.include(@visiblePageLinks(), 0)})

  nextClass: () ->
    React.addons.classSet({'hide': _.include(@visiblePageLinks(), @props.pageCount - 1)})

  visiblePageLinks: () ->
    visibleCount = 7
    half = Math.floor(visibleCount / 2)

    if @props.pageCount < visibleCount
      _.range(@props.pageCount)
    else if @props.page < half
      _.range(0, visibleCount)
    else if @props.page + half >= @props.pageCount
      _.range(@props.pageCount - visibleCount, @props.pageCount)
    else
      _.range(@props.page - half, @props.page + half + 1)
})
