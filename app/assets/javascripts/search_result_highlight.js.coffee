class SearchResultHighlight
  constructor: ->
    $(".search_results .term pre").each((k, v) ->
      html = $(v).html()
                  .replace(/gitlabelasticsearch→/g, '<span class="highlight_word"><span class="hljs-operator">')
                  .replace(/←gitlabelasticsearch/g, '</span></span>')
      $(v).empty().append(html)
    )

@SearchResultHighlight = SearchResultHighlight
