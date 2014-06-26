class SearchResultHighlight
  constructor: ->
    results = $(".search_results .term pre")
    results = $(".search_results .term") unless results.length

    results.each((k, v) ->
      html = $(v).html()
                  .replace(/gitlabelasticsearch→/g, '<span class="highlight_word"><span class="hljs-operator">')
                  .replace(/←gitlabelasticsearch/g, '</span></span>')
      $(v).empty().append(html)
    )

@SearchResultHighlight = SearchResultHighlight
