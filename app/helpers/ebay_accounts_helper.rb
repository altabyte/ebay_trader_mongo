module EbayAccountsHelper

  def ebay_account_daily_hits_chart(daily_hits)
    hits = daily_hits.reverse
    type = 'line' # 'column'
    LazyHighCharts::HighChart.new('aggregate_daily_hits') do |f|
      f.title(text: '')
      f.series(type: type, name: 'Hits/day', yAxis: 0, data: hits.map { |day| [day.flatten[0].strftime('%a, %-d %b ’%y'), day.flatten[1]] })

      f.legend(enabled: false)

      f.yAxis [
                  {
                      title: { text: '', margin: 0 },
                      gridLineWidth: 1,
                      min: 0
                  }
              ]

      f.xAxis [
                  {
                      categories: hits.map { |day| day.flatten[0].strftime('%A')[0] },
                      title: { text: '', margin: 0 },
                      tickInterval: 1,
                      gridLineWidth: 0
                  }
              ]

      f.plot_options(line: {
                         marker: {
                             radius: 1,
                             lineWidth: 1
                         }
                     })
    end
  end
end
