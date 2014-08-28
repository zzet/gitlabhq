getText = ->
  txt = ''
  if (txt = window.getSelection)
    txt = window.getSelection().toString()

  if (txt != '')
    $("table.text-file").addClass "hide-line-numbers"
  else
    $(".hide-line-numbers").removeClass "hide-line-numbers"

$(document).ready ->
  $("body").on "mouseup keyup", ->
    getText()
