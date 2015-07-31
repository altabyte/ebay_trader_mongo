require 'ebay_trading_pack'
require 'ebay_trading_pack/get_item'

include EbayTradingPack

class GetItemWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(auth_token, ebay_item_id)
    puts "\nRequesting details for eBay item: #{ebay_item_id}"

    get_item_request = EbayTradingPack::GetItem.new(auth_token, ebay_item_id)
    puts get_item_request.item_hash.to_yaml
  end
end