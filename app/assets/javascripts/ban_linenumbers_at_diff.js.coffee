getText = ->
  txt = ''
  if (txt = window.getSelection)
    txt = window.getSelection().toString()
  else
    txt = document.selection.createRange().text

  if (txt != '')
    $("table.text-file").addClass "hide-line-numbers"
  else
    $(".hide-line-numbers").removeClass "hide-line-numbers"

# getSelectedText = window.setInterval(getText, 200)
