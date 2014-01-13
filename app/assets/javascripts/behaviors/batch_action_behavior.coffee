#
# .js-batch-action-container
#   input(type=checkbox).js-batch-action-check-all
#
#   # n items
#   - entities.each do |entity|
#     input(type=checkbox value="entity.id").js-batch-action-item
#     input(type=checkbox value="entity.id").js-batch-action-item
#
#   .js-batch-action-content
#     %form
#       %input
#       %input(type=submit)
#
#     %a.js-batch-action-remove-link
#
# .js-batch-action-container - is container with batch action elements
# .js-batch-action-check-all - is checkbox for choose all items
# .js-batch-action-item - is checkbox where value is id of edited entity
# .js-batch-action-content - is block which visible when somebody item checked,
#                            this block should content form for edit enities
# .js-batch-action-remove-link - is link for remove checked entities
#   this link should be in content block
#
class BatchActionBehavior
  constructor: ->
    @container = $('.js-batch-action-container')
    @check_all_checkbox = @container.find('.js-batch-action-check-all')
    @items = @container.find('.js-batch-action-item')
    @content = @container.find('.js-batch-action-content')

    @check_all_checkbox.on('click', @checkallCheckboxHandler)
    @items.on('click', @itemCheckboxHandler)

    @content.on('confirm:complete', '.js-batch-action-remove-link', @removeLinkHandler)
    @content.on('submit', 'form', @contentFormHandler)

  checkallCheckboxHandler: (event) =>
    checked = $(event.target).prop('checked')
    @items.prop('checked', checked)

    @_updateContent()

  itemCheckboxHandler: (event) =>
    checked = @items.filter(':not(:checked)').length == 0
    @check_all_checkbox.prop('checked', checked)

    @_updateContent()

  contentFormHandler: (event) =>
    event.preventDefault()
    event.stopPropagation()

    form = $(event.target)
    url = form.attr('action')
    method = form.attr('method')
    data = form.serialize()
    data += "&#{@_getSerializedIds()}"

    $.ajax
      url: url
      type: method
      data: data
      success: ->
        window.location.reload()
      error: ->
        alert('Error! Refresh the page and try again.')

    return false

  removeLinkHandler: (event, answer) =>
    return false unless answer

    link = $(event.target)
    url = link.attr('href')

    $.ajax
      url: url
      type: 'DELETE'
      data: @_getSerializedIds()
      success: ->
        window.location.reload()
      error: ->
        alert('Error! Refresh the page and try again.')

    return false

  _updateContent: ->
    checked_items_count = @items.filter(':checked').length
    if checked_items_count > 0
      @content.show()
    else
      @content.hide()

  _getCheckedIds: ->
    @items.filter(':checked').map (i, e) ->
      $(e).val()

  _getSerializedIds: ->
    data = ''
    @_getCheckedIds().each (i, e)->
      data += "&ids[]=#{e}"
    data = data.slice(1)

$ ->
  new BatchActionBehavior()


