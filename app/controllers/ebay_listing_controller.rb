class EbayListingController < ApplicationController

  before_action :authenticate_user!

  def show
    @item_id = params[:item_id]
    redirect_to ebay_accounts_path, alert: 'eBay item ID not valid' unless @item_id

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
        logger.error = e.message
      end

    else
      redirect_to ebay_accounts_path, alert: "eBay item ID not '#{@item_id}' found" unless @item_id
    end
  end
end
