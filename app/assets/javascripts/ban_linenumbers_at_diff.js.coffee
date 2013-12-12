$ ->
  $(document).bind "textselect", (evt, string, element) ->
    unless string is ""
      $(element).parents("table").addClass "hide-line-numbers"
    else
      $(".hide-line-numbers").removeClass "hide-line-numbers"
