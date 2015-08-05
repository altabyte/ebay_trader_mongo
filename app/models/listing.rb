class Listing
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps # Define created_at and updated_at fields

  # The value assigned to {#listing_duration} for GTC listings.
  GTC ||= 365

  store_in collection: 'ebay_listings'

  embeds_one :best_offer_detail, class_name: 'Listing::BestOfferDetail'
  accepts_nested_attributes_for :best_offer_detail

  embeds_one :listing_detail, class_name: 'Listing::ListingDetail'
  accepts_nested_attributes_for :listing_detail
  validates :listing_detail, presence: true

  embeds_one :selling_state, class_name: 'Listing::SellingState', validate: true
  accepts_nested_attributes_for :selling_state
  validates :selling_state, presence: true

  embeds_one :store_front, class_name: 'Listing::Storefront', validate: true
  accepts_nested_attributes_for :store_front

  # @return [String] the eBay username of the seller.
  field :seller_username, type: String
  attr_readonly :seller_username
  validates :seller_username, presence: true

  field :listing_type, type: String
  validates :listing_type, presence: true

  # The eBay ID of the item from which this was re-listed.
  # @return [Fixnum] the parent listing eBay ID, or +nil+ if this is a fresh listing.
  field :relist_parent_id, type: Fixnum

  # @return [Fixnum] the eBay item ID.
  field :item_id, type: Fixnum
  attr_readonly :item_id
  validates :item_id, presence: true, uniqueness: true
  index({ item_id: 1 }, { unique: true, name: 'item_id_index' })

  # @return [String] the SKU, also known as the custom label in the UK.
  field :sku, type: String
  index({ sku: 1 }, { name: 'sku_index' })
  validates :sku, presence: true

  # @return [Fixnum] the number of items originally listed.
  field :quantity_listed, type: Fixnum, default: 0
  validates :quantity_listed, numericality: { only_integer: true, greater_than: 0 }

  # @return [Fixnum] the number of items currently available.
  field :quantity_available, type: Fixnum, default: 0

  # @return [String] the listing title.
  field :title, type: String
  validates :title, presence: true

  # @return [String] an optional sub-title.
  field :sub_title, type: String

  # @return [Fixnum] the listing duration in days where a value greater than 30 represents GTC.
  field :listing_duration, type: Fixnum
  validates :listing_duration, numericality: { only_integer: true, greater_than: 0 }

  # @return [Hash] a hash of the picture details.
  field :picture_details, type: Hash

  # @return [String] 3 character currency ISO code.
  field :currency, type: String, default: 'GBP'

  # The start price of this listing, which is actually its current price.
  # If the item is currently on sale then +sale_price+ will show the discounted price.
  # @return [Money] the start price.
  field :start_price, type: Money
  validates :start_price, presence: true

  # @return [Money] the reserve price of +nil+ if none set.
  field :reserve_price, type: Money

  # @return [String] The name of the site on which the item is listed.
  # @see http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/GetItem.html#Response.Item.Site
  # @note The listing site affects the business logic and validation rules that are applied to the request.
  field :site, type: String
  validates :site, presence: true

  # @return [Fixnum] the primary category ID.
  field :primary_category_id, type: Fixnum
  validates :primary_category_id, presence: true

  # @return [Fixnum] secondary category ID or nil.
  field :secondary_category_id, type: Fixnum

  # @return [Boolean] +true+ if this listing is hidden from search.
  field :hide_from_search, type: Boolean, default: false

  # The reason {#hide_from_search} may be +true+. Can be one of:
  # * DuplicateListing
  # * OutOfStock
  # @return [String] message describing why listing is hidden from search results.
  field :reason_hide_from_search, type: String

  # Determine if GetItFast shipping rules apply to this listing.
  # @return [Boolean] +true+ if GetItFast is supported
  # @note Not supported for UK Store Inventory format items.
  field :get_it_fast, type: Boolean, default: false

  # @return [Boolean] +true+ if this is a top-rated listing.
  field :top_rated_listing, type: Boolean, default: false

  # @return [Fixnum] The maximum number of business days the seller commits to for preparing an item to be shipped after receiving a cleared payment.
  field :dispatch_time_max, type: Fixnum, default: 3

  # Set the listing duration as a number of days.
  # This can be an integer number of days, or a string such as
  # 'Days_30' or 'GTC'.
  # @param [String|Fixnum] duration
  def listing_duration=(duration)
    if duration.is_a? Fixnum
      duration = 0 if duration < 0
      duration = GTC if duration > GTC
    else
      duration = duration.to_s.downcase
      if match = duration.match(/Days_([0-9]+)/i)
        duration = match[1]
      elsif duration.match(/GTC/i)
        duration = GTC
      end
    end
    self[:listing_duration] = duration.to_i
  end

  # Determine if this is a GTC listing.
  # @return +true+ if {#listing_duration} has a value greater than 30 days.
  #
  def gtc?
    listing_duration >= GTC
  end

  # @return [Boolean] +true+ if best offer is enabled.
  def has_best_offer?
    return false if best_offer_detail.nil?
    best_offer_detail.best_offer_enabled?
  end

  def on_sale_now?
    selling_state.has_promotion? && promotional_sale_detail.on_sale_now?
  end
end
