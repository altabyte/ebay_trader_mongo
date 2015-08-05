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

  embeds_one :item_specific,
             store_as: :item_specific,
             as: :name_value_list_containable,
             class_name: 'Listing::NameValueListContainer'
  accepts_nested_attributes_for :item_specific

  embeds_one :picture_detail, class_name: 'Listing::PictureDetail'
  accepts_nested_attributes_for :picture_detail

  embeds_one :revise_state, class_name: 'Listing::ReviseState'
  accepts_nested_attributes_for :revise_state

  embeds_one :selling_state, class_name: 'Listing::SellingState' #, store_as: :selling_status
  accepts_nested_attributes_for :selling_state
  validates :selling_state, presence: true

  embeds_one :store_front, class_name: 'Listing::Storefront'
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

  # The number of page views.
  field :hit_count, type: Fixnum, default: 0

  # The number of people watching this listing.
  field :watch_count, type: Fixnum, default: 0

  # @return [Boolean] +true+ if this listing is hidden from search.
  field :hide_from_search, as: :hide_from_search?, type: Boolean, default: false

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

  # Use UUID to ensure that you only list a particular item once.
  # If you add an item and do not get a response, resend the request
  # with the same UUID. If the item was successfully listed the first time,
  # you will receive an error message for trying to use a UUID that you
  # have already used.
  # @return [String] the UUID value set when listing/revising the item.
  field :uuid, type: String

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
    selling_state.has_promotion? && selling_state.promotional_sale_detail.on_sale_now?
  end

  def summary
    show_photo_urls = true
    s = ''
    s << "!! Hidden from search !! - #{reason_hide_from_search}\n" if hide_from_search?
    s << "#{title.ljust(82)}[#{selling_state.listing_state}]\n"

    s << "  #{selling_state.current_price.symbol}#{selling_state.current_price}"
    if has_best_offer?
      s << " but will accept #{listing_detail.best_offer_auto_accept_price.symbol}#{listing_detail.best_offer_auto_accept_price}" if listing_detail.best_offer_auto_accept_price
      s << " [min #{listing_detail.minimum_best_offer_price.symbol}#{listing_detail.minimum_best_offer_price}]" if listing_detail.minimum_best_offer_price && listing_detail.minimum_best_offer_price != listing_detail.best_offer_auto_accept_price
      s << " - #{best_offer_detail.best_offer_count} offers"
    end
    s << "\n"

    if on_sale_now?
      sale = selling_state.promotional_sale_detail
      s << "  ON SALE NOW! #{sale.percentage_discount}% OFF"
      s << " [was #{sale.original_price.symbol}#{sale.original_price}]"
      s << " from #{sale.start_time.strftime('%H:%M%P on %A')}"
      s << " until #{sale.end_time.strftime('%H:%M%P on %A')}\n"
    end

    s << "  #{selling_state.quantity_sold} sold, #{watch_count} watchers, #{hit_count} page views\n"
    s << "    SKU: #{sku},    eBay ID: #{item_id},    Photos: #{picture_detail.count}\n" #{picture_details[:picture_url].count}\n"
    if show_photo_urls
      picture_detail.picture_url.each do |url|
        s << "      [#{url}]\n"
      end

    end

    s << "    #{gtc? ? 'GTC' : "#{listing_duration} day"} [#{listing_detail.days_active} days active]"
    s << "    Category: #{primary_category_id}\n"
    s << "  #{listing_detail.start_time.strftime('%l:%H%P %A %-d %b').strip} until #{listing_detail.end_time.strftime('%l:%H%P %A %-d %b %Y').strip}\n"

   # Print item specifics
    name_length_max = 0
    item_specific.names.each { |name| name_length_max = [name_length_max, name.length].max }
    item_specific.each do |name, value|
      s << "#{name.rjust(name_length_max + 10)}  ->  #{value}\n"
    end

    s
  end
end
