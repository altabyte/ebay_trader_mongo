class EbayListingController < ApplicationController

  before_action :authenticate_user!

  def show
    @item_id = params[:item_id]
    redirect_to(ebay_accounts_path, alert: 'eBay item ID not valid') and return unless @item_id

    if EbayListing.where(item_id: @item_id).exists?
      @listing = EbayListing.where(item_id: @item_id).first
      @status = @listing.selling_state.listing_state
      @currecy_symbol = '&pound;'.html_safe

      @photos = []
      begin
        @listing.picture_detail.picture_url.each do |photo|
          @photos << photo
        end
      rescue Exception => e
        logger.error e.message
      end

      date = Time.now.utc.to_date
      @number_of_days = 130
      hits_docs = EbayListingDailyHitCount
                      .where(item_id: @item_id, :date.lte => date)
                      .where(:date.gte => (date - @number_of_days.days))
                      .order_by(date: :asc).all.entries

      balance = 0
      balance = hits_docs.first.closing_balance unless hits_docs.empty?
      @daily_hits = []
      (@number_of_days.downto(0)).each do |i|
        day = date - i.days
        struct = Struct.new(:date, :opening_balance, :closing_balance, :total_hits, :on_sale).new(day, balance, balance, 0)
        @daily_hits << struct

        daily_data = hits_docs.select { |doc| doc.date == day }.first
        if daily_data
          struct.opening_balance = daily_data.opening_balance
          struct.closing_balance = daily_data.closing_balance
          struct.total_hits = daily_data.total_hits

          on_sale = false
          daily_data.hours.each { |h| on_sale = true if h.on_sale }
          struct.on_sale = on_sale

          balance = daily_data.closing_balance
        end
      end

      series_1_color = '#008100'
      series_2_color = '#009AE1'
      # Examples:
      #
      #   https://github.com/michelson/lazy_high_charts/blob/master/spec/dummy_rails/app/controllers/application_controller.rb
      #
      #   http://api.highcharts.com/highcharts#yAxis
      #
      @chart = LazyHighCharts::HighChart.new('graph') do |f|
        f.title(text: '')
        f.chart(zoomType: 'xy', alignTicks: false)
        f.series(type: 'line', name: 'Hits/day', yAxis: 0, color: series_1_color, data: @daily_hits.map { |day| [day.date.strftime('%a %-d %b ’%y'), day.total_hits] })
        f.series(type: 'spline', name: 'Total hits', yAxis: 1, color: series_2_color, data: @daily_hits.map { |day| [day.date.strftime('%a %-d %b ’%y'), day.closing_balance] })

        f.plot_options(spline: {
            marker: {
                radius: 1
            }
        },
                       line: {
                           marker: {
                               radius: 1,
                               lineWidth: 1
                           }
                       })

        f.legend(enabled: false)

        f.xAxis(categories: (@number_of_days.downto(0)).map { |i| (date - i.days).strftime('%A')[0] }, crosshair: true)

        # http://api.highcharts.com/highcharts#yAxis
        f.yAxis [
                    {
                        #tickAmount: 6,
                        #min: 0,
                        #max: (@daily_hits.min { |d1, d2| d2.total_hits <=> d1.total_hits }.total_hits),
                        crosshair: true,
                        minPadding: 0.0,
                        startOnTick: false,
                        endOnTick: false,
                        title: { text: '', margin: 0, style: { color: series_1_color }},
                        labels: { style: { color: series_1_color }}
                    },
                    {
                        opposite: true,
                        #tickAmount: 6,
                        #min: (@daily_hits.first.closing_balance),
                        #max: (@daily_hits.last.closing_balance),
                        minPadding: 0.0,
                        #startOnTick: false,
                        endOnTick: false,
                        crosshair: true,
                        gridLineWidth: 0,
                        title: { text: '', margin: 0, style: { color: series_2_color }},
                        labels: { format: '{value}', style: { color: series_2_color }}
                    }
                ]
      end
    else
      redirect_to ebay_accounts_path, alert: "eBay item ID '#{@item_id}' not found"
    end
  end


  def no_sales
    @seller_id = params[:seller_id]
    @site = params[:site] || 'UK'
    @quantity_sold = (params[:quantity_sold] || 0).to_i
    @order_by = case params[:order_by]
                  when /hit/ then
                    'hit_count'
                  when /watch/ then
                    'watch_count'
                  when /age/ then
                    'listing_detail.start_time'
                  when /price/ then
                    'selling_state.current_price'
                  else
                    'sku'
                end

    @order = params.key?(:order) && %w'ASC DESC'.include?(params[:order].upcase) ? params[:order].upcase : 'DESC'
    @items = []
    begin
      @days = (params[:days] || 90).to_i
      seller = EbayUser.where(user_id: @seller_id).first
      criteria = seller.ebay_listings.active.older_than(@days).where(site: @site).where('selling_state.quantity_sold' => @quantity_sold).order_by(@order_by => @order)
      @items = criteria.all.entries
      @items.each { |listing| puts "#{listing.item_id}   #{listing.sku.to_s.rjust(5)}   #{listing.hit_count.to_s.rjust(3)}   #{listing.watch_count.to_s.rjust(3)}" }
    rescue Exception => e
      logger.error e.message
      redirect_to ebay_accounts_path, alert: e.message
    end
  end
end
