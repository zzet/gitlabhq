class Diff
  constructor: ->
    $(document).on('click', '.js-unfold', (event) =>
      target = $(event.target)
      unfoldBottom = target.hasClass('js-unfold-bottom')
      unfold = true

      [old_line, line_number] = @lineNumbers(target.parent())
      offset = line_number - old_line

      if unfoldBottom
        line_number += 1
        since = line_number
        to = line_number + 20
      else
        [prev_old_line, prev_new_line] = @lineNumbers(target.parent().prev())
        line_number -= 1
        to = line_number
        if line_number - 20 > prev_new_line + 1
          since = line_number - 20
        else
          since = prev_new_line + 1
          unfold = false

      link = $('.js-view-file').attr('href') + '/diff'
      params =
        since: since
        to: to
        bottom: unfoldBottom
        offset: offset
        unfold: unfold

      $.get(link, params, (response) =>
        target.parent().replaceWith(response)
      )
    )

  lineNumbers: (line) ->
    lines = line.children().slice(0, 2)
    line_numbers = ($(l).attr('data-linenumber') for l in lines)
    (parseInt(line_number) for line_number in line_numbers)


@Diff = Diff
