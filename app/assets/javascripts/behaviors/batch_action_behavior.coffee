#
# .CONTAINER_CLASS
#   input(type=checkbox).CHECK_ALL_CHECKBOX_CLASS
#
#   # n items
#   - entities.each do |entity|
#     input(type=checkbox value="entity.id").ITEMS_CHECKBOX_CLASS
#     input(type=checkbox value="entity.id").ITEMS_CHECKBOX_CLASS
#
#   .CONTENT_CLASS
#     %form
#       %input
#       %input(type=submit)
#
#     %a.REMOVE_LINK_CLASS
#
# CONTAINER_CLASS is container with batch action elements
# CHECK_ALL_CHECKBOX_CLASS is checkbox for choose all items
# ITEMS_CHECKBOX_CLASS is checkbox where value is id of edited entity
# CONTENT_CLASS is block which visible when somebody item checked
#   this block should content form for edit enities
# REMOVE_LINK_CLASS is link for remove checked entities
#   this link should be in content block
#
class BatchActionBehavior
  CONTAINER_CLASS = '.js-batch-action-container'
  CHECK_ALL_CHECKBOX_CLASS = '.js-batch-action-check-all'
  ITEMS_CHECKBOX_CLASS = '.js-batch-action-item'
  CONTENT_CLASS = '.js-batch-action-content'
  REMOVE_LINK_CLASS = '.js-batch-remove-link'

  constructor: ->
    @container = $(CONTAINER_CLASS)
    @check_all_checkbox = @container.find(CHECK_ALL_CHECKBOX_CLASS)
    @items = @container.find(ITEMS_CHECKBOX_CLASS)
    @content = @container.find(CONTENT_CLASS)

    @container.on('click', CHECK_ALL_CHECKBOX_CLASS, @checkallCheckboxHandler)
    @items.on('click', @itemCheckboxHandler)

    @content.on('confirm:complete', REMOVE_LINK_CLASS, @removeLinkHandler)
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


