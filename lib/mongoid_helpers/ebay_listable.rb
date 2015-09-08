require 'active_support/core_ext/object/deep_dup'
require 'active_support/time'

require 'ebay_trader_support'
require 'ebay_trader_support/helpers/item_details'

module EbayListable

  # Determine if +ebay_username+ is one of *my* selling accounts.
  #
  # The eBay user IDs for my selling accounts are stored in environmental variables
  # with keys beginning with +'EBAY_API_USERNAME_'+.
  #
  # @todo Find my seller accounts from {EbayUser} models rather than environmental variables.
  #
  # @param [String] ebay_username the eBay username to be verified.
  # @return [Boolean] +true+ if +ebay_username+ is one of my seller accounts.
  #
  def my_seller_account_username?(ebay_username)
    return false if ebay_username.blank?
    my_seller_ids = []
    env_user_keys = ENV.keys.find_all { |key| key =~ /^EBAY_API_USERNAME_/ }
    env_user_keys.each { |key| my_seller_ids << ENV[key] }
    my_seller_ids << 'TESTUSER_seller_1' # Used in my RSpec tests
    my_seller_ids.include?(ebay_username.downcase)
  end

  def save(item_details, seller, call_name, timestamp)
    raise 'ItemDetails not valid' unless item_details && item_details.is_a?(EbayTraderSupport::ItemDetails)
    item_id = item_details.item_id

    item_hash = restructure_item_hash(item_details.item_hash.deep_dup.merge({ seller: seller }))
    #puts item_hash.to_yaml

    listing = EbayListing.where(item_id: item_id).exists? ? EbayListing.find_by(item_id: item_id) : EbayListing.new(item_hash)
    last_updated = listing.last_updated || Time.parse('1995-09-03T00:00:00 UTC') # eBay's Birthday
    if timestamp > last_updated
      listing.add_timestamp call_name, timestamp
      listing.update_attributes(item_hash) unless listing.new_record?
    end
    listing.save!
  end

  # Restructure the +item_hash+ so that it is compatible with MongoDB
  # and eliminate any redundant information.
  # @param [Hash] item_hash the Hash of data describing each item
  #               from API calls such as GetItem, GetSellerList etc.
  # @return [Hash] +item_hash+ restructured.
  def restructure_item_hash(item_hash)
    seller = item_hash[:seller]
    seller_username = case
                        when seller.is_a?(Hash) then item_hash[:seller][:user_id]
                        when seller.is_a?(HashWithIndifferentAccess) then item_hash[:seller][:user_id]
                        when seller.is_a?(EbayUser) then seller.user_id
                        else
                          nil
                      end

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
      #item_hash.delete(:seller_profiles)
      #item_hash.delete(:shipping_detail)            # Maybe should leave this in?
      item_hash.delete(:shipping_package_detail)
    end
    item_hash
  end
end