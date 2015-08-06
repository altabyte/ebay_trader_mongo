require 'ebay_trading_pack'
require 'ebay_trading_pack/get_item'
require 'mongoid_helpers/listing_document_helper'

include EbayTradingPack

class GetItemWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  include ListingDocumentHelper

  def perform(auth_token, ebay_item_id)
    puts "\nRequesting details for eBay item: #{ebay_item_id}"

    get_item_request = EbayTradingPack::GetItem.new(auth_token, ebay_item_id)
    save(get_item_request, GetItem::CALL_NAME, get_item_request.timestamp)
    puts get_item_request.to_s 2
  end
end