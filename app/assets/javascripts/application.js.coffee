# This is a manifest file that'll be compiled into including all the files listed below.
# Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
# be included in the compiled file accessible from http://example.com/assets/application.js
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
#= require jquery
#= require jquery.ui.all
#= require jquery_ujs
#= require jquery.cookie
#= require jquery.endless-scroll
#= require jquery.highlight
#= require jquery.history
#= require jquery.waitforimages
#= require jquery.atwho
#= require jquery.scrollTo
#= require jquery.blockUI
#= require jquery.sticky
#= require jquery-friendly_id
#= require turbolinks
#= require jquery.turbolinks
#= require bootstrap
#= require select2
#= require raphael
#= require g.raphael-min
#= require g.bar-min
#= require branch-graph
#= require highlight.pack
#= require ace/ace
#= require ace/ext-searchbox
#= require d3
#= require underscore
#= require nprogress
#= require nprogress-turbolinks
#= require dropzone
#= require semantic-ui/sidebar
#= require mousetrap
#= require shortcuts
#= require shortcuts_navigation
#= require shortcuts_dashboard_navigation
#= require shortcuts_issueable
#= require shortcuts_network
#= require_tree .

window.slugify = (text) ->
  text.replace(/[^-a-zA-Z0-9]+/g, '_').toLowerCase()

window.ajaxGet = (url) ->
  $.ajax({type: "GET", url: url, dataType: "script"})

window.showAndHide = (selector) ->

window.errorMessage = (message) ->
  ehtml = $("<p>")
  ehtml.addClass("error_message")
  ehtml.html(message)
  ehtml

window.split = (val) ->
  return val.split( /,\s*/ )

window.extractLast = (term) ->
  return split( term ).pop()

window.rstrip = (val) ->
  return val.replace(/\s+$/, '')

# Disable button if text field is empty
window.disableButtonIfEmptyField = (field_selector, button_selector) ->
  field = $(field_selector)
  closest_submit = field.closest('form').find(button_selector)

  closest_submit.disable() if rstrip(field.val()) is ""

  field.on 'input', ->
    if rstrip($(@).val()) is ""
      closest_submit.disable()
    else
      closest_submit.enable()

# Disable button if any input field with given selector is empty
window.disableButtonIfAnyEmptyField = (form, form_selector, button_selector) ->
  closest_submit = form.find(button_selector)
  empty = false
  form.find('input').filter(form_selector).each ->
    empty = true if rstrip($(this).val()) is ""

  if empty
    closest_submit.disable()
  else
    closest_submit.enable()

  form.keyup ->
    empty = false
    form.find('input').filter(form_selector).each ->
      empty = true if rstrip($(this).val()) is ""

    if empty
      closest_submit.disable()
    else
      closest_submit.enable()

window.sanitize = (str) ->
  return str.replace(/<(?:.|\n)*?>/gm, '')

window.linkify = (str) ->
  exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
  return str.replace(exp,"<a href='$1'>$1</a>")

window.simpleFormat = (str) ->
  linkify(sanitize(str).replace(/\n/g, '<br />'))

window.unbindEvents = ->
  $(document).unbind('scroll')
  $(document).off('scroll')

document.addEventListener("page:fetch", unbindEvents)

$ ->
  # Click a .one_click_select field, select the contents
  $(".one_click_select").on 'click', -> $(@).select()

  $('.remove-row').bind 'ajax:success', ->
    $(this).closest('li').fadeOut()

  # Initialize select2 selects
  $('select.select2').select2(width: 'resolve', dropdownAutoWidth: true)

  # Close select2 on escape
  $('.js-select2').bind 'select2-close', ->
    setTimeout ( ->
      $('.select2-container-active').removeClass('select2-container-active')
      $(':focus').blur()
    ), 1

  # Initialize tooltips
  $('.has_tooltip').tooltip()

  # Bottom tooltip
  $('.has_bottom_tooltip').tooltip(placement: 'bottom')

  # Form submitter
  $('.trigger-submit').on 'change', ->
    $(@).parents('form').submit()

  $("abbr.timeago").timeago()
  $('.js-timeago').timeago()

  # Flash
  if (flash = $(".flash-container")).length > 0
    flash.click -> $(@).fadeOut()
    flash.show()
    setTimeout (-> flash.fadeOut()), 5000

  # Disable form buttons while a form is submitting
  $('body').on 'ajax:complete, ajax:beforeSend, submit', 'form', (e) ->
    buttons = $('[type="submit"]', @)

    switch e.type
      when 'ajax:beforeSend', 'submit'
        buttons.disable()
      else
        buttons.enable()

  # Show/Hide the profile menu when hovering the account box
  $('.account-box').hover -> $(@).toggleClass('hover')

  # Commit show suppressed diff
  $(".diff-content").on "click", ".supp_diff_link", ->
    $(@).next('table').show()
    $(@).remove()

  # Show/hide comments on diff
  $("body").on "click", ".js-toggle-diff-comments", (e) ->
    $(@).find('i').
      toggleClass('icon-chevron-down').
      toggleClass('icon-chevron-up')
    $(@).closest(".diff-file").find(".notes_holder").toggle()
    e.preventDefault()

(($) ->
  # Disable an element and add the 'disabled' Bootstrap class
  $.fn.extend disable: ->
    $(@).attr('disabled', 'disabled').addClass('disabled')

  # Enable an element and remove the 'disabled' Bootstrap class
  $.fn.extend enable: ->
    $(@).removeAttr('disabled').removeClass('disabled')

)(jQuery)
