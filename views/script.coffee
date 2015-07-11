# Highcharts.getOptions().colors
# ["#7cb5ec", "#434348", "#90ed7d", "#f7a35c", "#8085e9", "#f15c80", "#e4d354", "#2b908f", "#f45b5b", "#91e8e1"]
langColors =
  "Assembler"                : "#b92deb"
  "AWK (gawk)"               : "#7cb5ec"
  "Bash"                     : "#a85817"
  "Brainf**k"                : "rgb(150, 134, 109)"
  "C#"                       : "#7cecb0"
  "C++ 4.3.2"                : "#fff61f"
  "C++ 4.9.2"                : "#bffe65"
  "C++ 14"                   : "#a1f6be"
  "C99 strict "              : "#e2c715"
  "C"                        : "#c1ad29"
  "D"                        : "#ecab7c"
  "Factor"                   : "#967cec"
  "Fortran"                  : "#98c1e9"
  "Go"                       : "#a33b08"
  "Groovy"                   : "#02a84e"
  "Haskell"                  : "#ffb6b6"
  "Java7"                    : "#7cb5ec"
  "JavaScript (rhino)"       : "#7ce5ec"
  "JavaScript (spidermonkey)": "#62b9bf"
  "Java"                     : "#005bb3"
  "Octave"                   : "#7cb5ec"
  "Pascal (fpc)"             : "#145798"
  "Perl"                     : "#5bb0fc"
  "PHP"                      : "#ffa361"
  "Python"                   : "#038b15"
  "Ruby"                     : "#af0000"
  "R"                        : "#ff0000"
  "Scala"                    : "#980a0a"
  "VB.NET"                   : "#ff26e9"

sigmoid = (t) ->
  1/(1+Math.pow Math.E, -t)

pmap = (value, istart, istop, ostart, ostop) ->
  ostart + (ostop - ostart) * ((value - istart) / (istop - istart))

arrayObjectIndexOf = (ary, elem, prop) ->
  for i in [0...ary.length] by 1
    return i if ary[i][prop] is elem
  return -1

getPropertyLike = (obj, name) ->
  for exactName in Object.keys(obj)
    return exactName if exactName.match name

$ ->
  $("#check-all").click ->
    $("#display-langs input:checkbox").prop 'checked', @checked

  $('#refresh').click ->
    # display options
    nthDeathcolo   = $("#nth-deathcolo").val()
    showMinAvgArea = $("#show-min-avg-area").prop 'checked'
    magnifyPoints  = $("#magnify-points").prop 'checked'
    displayLangs   = $.makeArray(
          $("#display-langs input:checkbox")
            .filter (i,elm) -> $(elm).prop 'checked'
            .map (i,elm) -> $(elm).val()
        )
    # fetch API
    $.getJSON "/stats/#{nthDeathcolo}", (res) ->
      chartTitle = res.title
      numLangMax = Math.max.apply null, res.langs.map (a) -> a.length
      dates      = res.dates.reverse()
      numDays    = dates.length
      series     = []
      langs      = {}
      propName   =
        lang : "言語名"
        num  : "人数"
        min  : getPropertyLike res.langs[0][0], /最短/
        avg  : getPropertyLike res.langs[0][0], /平均/
      # make objects for each languages
      for i in [0...numDays]
        for j in [0...numLangMax]
          if res.langs[i][j]
            name = res.langs[i][j][propName.lang]
            if displayLangs.indexOf(name) isnt -1
              langs[name] or= {}
              langs[name][propName.num] or= []
              langs[name][propName.min] or= []
              langs[name][propName.avg] or= []
      # collect data for each languages
      for i in [0...numDays]
        for name, lang of langs
          j = arrayObjectIndexOf res.langs[i], name, propName.lang
          if j isnt -1
            lang[propName.num][i] = res.langs[i][j][propName.num]|0
            lang[propName.min][i] =
              y: res.langs[i][j][propName.min]
              marker:
                radius: if magnifyPoints then pmap(sigmoid(lang[propName.num][i]/2), 0.5, 1.0, 1, 10) else 3
            lang[propName.avg][i] = [lang[propName.min][i].y, res.langs[i][j][propName.avg]]
          else
            lang[propName.min][i] = null
            lang[propName.avg][i] = null
      # format and register the data to Highcharts series
      for name in Object.keys langs
        color = langColors[name]
        series.push
          name: name
          data: langs[name][propName.min].reverse()
          zIndex: 1
          color: color
          marker:
            fillColor: 'white'
            lineWidth: 2
            lineColor: color
        if showMinAvgArea
          series.push
            name: "-> min-avg"
            data: langs[name][propName.avg].reverse()
            type: 'arearange'
            lineWidth: 0
            linkedTo: ':previous'
            color: color
            fillOpacity: 0.3
            zIndex: 0
      # set title
      $("title").text chartTitle
      # scroll to the chart
      $('html,body').animate
        scrollTop: $('#death-colo-chart').offset().top
      , 'normal'
      # highcharts options
      $('#death-colo-chart').highcharts
        chart:
          zoomType: 'x'
        title:
          text: chartTitle
        xAxis:
          categories: dates
        yAxis:
          title:
            text: propName.min.substring 2
        tooltip:
          crosshairs: true
          shared: true
          valueSuffix: ''
        legend:
          layout: 'vertical'
          align: 'right'
          verticalAlign: 'middle'
          borderWidth: 0
        series: series
