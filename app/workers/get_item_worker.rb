require 'ebay_trading_pack'
require 'ebay_trading_pack/get_item'
require 'mongoid_helpers/ebay_userable'
require 'mongoid_helpers/listing_document_helper'

include EbayTradingPack

class GetItemWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  include EbayUserable
  include ListingDocumentHelper

  def perform(auth_token, ebay_item_id)
    puts "\nRequesting details for eBay item: #{ebay_item_id}"

    get_item_request = EbayTradingPack::GetItem.new(auth_token, ebay_item_id)
    raise get_item_request.errors.first[:short_message] if get_item_request.has_errors?

    seller_hash = get_item_request.item_hash[:seller]
    seller = find_or_create_ebay_user(seller_hash, get_item_request.timestamp)

    save(get_item_request, seller, GetItem::CALL_NAME, get_item_request.timestamp)
    puts get_item_request.to_s 2
  end
end