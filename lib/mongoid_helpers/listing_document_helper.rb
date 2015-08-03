require 'ebay_trading_pack'
require 'ebay_trading_pack/helpers/item_details'

module ListingDocumentHelper

  def save(item_details, call_name, timestamp)
    raise 'ItemDetails not valid' unless item_details && item_details.is_a?(EbayTradingPack::ItemDetails)
    item_id = item_details.item_id

    item_hash = restructure_item_hash(item_details.item_hash)

    puts "Call name:  #{call_name}"
    puts "Timestamp:  #{timestamp}"
    puts "Title:      #{item_details.title}"
    puts "Item:       #{item_id} => #{item_details.sku}"

    begin
      listing = Listing.find_by(item_id: item_id)
      item_hash[:title] = 'Upgraded Awesome Item'
      listing.update_attributes(item_hash)
    rescue Mongoid::Errors::DocumentNotFound
      listing = Listing.create!(item_hash)
    end

    listing.reload
    puts listing.title

  end

  def restructure_item_hash(item_hash)

    item_hash[:listing_detail] = item_hash.delete(:listing_details)

    item_hash
  end

end