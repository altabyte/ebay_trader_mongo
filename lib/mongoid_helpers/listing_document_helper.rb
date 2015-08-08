require 'active_support/core_ext/object/deep_dup'

require 'ebay_trading_pack'
require 'ebay_trading_pack/helpers/item_details'

module ListingDocumentHelper

  # Determine if +ebay_username+ is one of my selling accounts.
  # @param [String] ebay_username the eBay username to be verified.
  # @return [Boolean] +true+ if +ebay_username+ belongs to me.
  #
  def my_seller_account_username?(ebay_username)
    my_sellers_ids = []
    my_sellers_ids << ENV['EBAY_API_USERNAME_AR']
    my_sellers_ids << ENV['EBAY_API_USERNAME_TT']
    my_sellers_ids << 'seller_1'                    # Used in my RSpec tests
    my_sellers_ids.include?(ebay_username.downcase)
  end

  def save(item_details, call_name, timestamp)
    raise 'ItemDetails not valid' unless item_details && item_details.is_a?(EbayTradingPack::ItemDetails)
    item_id = item_details.item_id

    item_hash = restructure_item_hash(item_details.item_hash.deep_dup)
    puts item_hash.to_yaml

    puts "Call name:  #{call_name}"
    puts "Timestamp:  #{timestamp}"

    begin
      listing = EbayListing.find_by(item_id: item_id)
      item_hash[:title] = 'Upgraded Awesome Item'
      listing.update_attributes(item_hash)
    rescue Mongoid::Errors::DocumentNotFound
      listing = EbayListing.create!(item_hash)
    end
  end

  # Restructure the +item_hash+ so that it is compatible with MongoDB
  # and eliminate any redundant information.
  # @param [Hash] item_hash the Hash of data describing each item
  #               from API calls such as GetItem, GetSellerList etc.
  # @return [Hash] +item_hash+ restructured.
  def restructure_item_hash(item_hash)
    seller_username = item_hash[:seller][:user_id]
    item_hash[:seller_username] = seller_username

    item_hash.deep_transform_keys! do |key|
      key = key.to_s
      key = key.gsub('_details', '_detail') if key.match /_details$/i
      key = key.gsub('_profiles', '_profile') if key.match /_profiles$/i
      key = key.gsub('_status', '_state') if key.match /_status$/i    # 'status' is considered plural by Active Support.

      key = 'exclude_ship_to_locations' if key == 'exclude_ship_to_location'
      key = 'international_shipping_service_options' if key == 'international_shipping_service_option'
      key = 'name_value_lists' if key == 'name_value_list'
      key = 'quantity_listed' if key == 'quantity'
      key = 'ship_to_locations' if key == 'ship_to_location'
      key = 'variation_detail' if key == 'variations'
      key = 'variations' if key == 'variation'
      key = 'variation_specifics_sets' if key == 'variation_specifics_set'
      key = 'variation_specific_picture_sets' if key == 'variation_specific_picture_set'
      key
    end

    category_id = item_hash.deep_find([:primary_category, :category_id])
    unless category_id.nil?
      item_hash.delete(:primary_category)
      item_hash[:primary_category_id] = category_id
    end

    category_id = item_hash.deep_find([:secondary_category, :category_id])
    unless category_id.nil?
      item_hash.delete(:secondary_category)
      item_hash[:secondary_category_id] = category_id
    end

    # Remove data that is generally the same in every ebay_listing.
    if my_seller_account_username? seller_username
      item_hash.delete(:business_seller_detail)
      item_hash.delete(:buyer_guarantee_price)      # For the Australia site only
      item_hash.delete(:buyer_requirement_detail)
      item_hash.delete(:return_policy)
      item_hash.delete(:seller)
      #item_hash.delete(:seller_profiles)
      #item_hash.delete(:shipping_detail)            # Maybe should leave this in?
      item_hash.delete(:shipping_package_detail)
      #item_hash.delete(:ship_to_locations)
    end
    item_hash
  end
end