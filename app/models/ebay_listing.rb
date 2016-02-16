class EbayListing
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  # For functionality shared with Variation
  #  app/models/concerns/ebay_listing_item.rb
  include EbayListingItem

  store_in collection: 'ebay_listings'

  #before_save :update_hit_count_history
  after_save  :update_daily_hit_count

  # The value assigned to {#listing_duration} for GTC listings.
  GTC ||= 365

  scope :active, -> { where('selling_state.listing_state' => 'Active') } do
    def on_sale_now
      #where('selling_state.promotional_sales' => { '$elemMatch' => { end_time: { '$gt' => Time.now.utc} } })
      where('selling_state.promotional_sales.end_time' => {'$gt' => Time.now.utc})
    end

    def not_on_sale_now
      ids = on_sale_now.only(:id).map { |listing| listing.id }
      not_in(id: ids)
    end
  end
  scope :gtc, -> { where(listing_duration: GTC) }
  scope :ended, -> { where('selling_state.listing_state' => {'$ne' => 'Active'}) }
  scope :with_variations, -> { where(variation_detail: {'$ne' => nil}) }
  scope :without_variations, -> { where(variation_detail: nil) }
  scope :older_than, -> (days) { gtc.active.where('listing_detail.start_time' => {'$lt' => Time.now.utc - days.days}) }

  belongs_to :seller, class_name: EbayUser.name

  has_many :hits, class_name: EbayListing::Hit.name, order: :count.asc, autosave: true

  has_many :ebay_listing_daily_hit_counts, order: :date.asc, dependent: :nullify#, autosave: true

  embeds_one :best_offer_detail, class_name: EbayListing::BestOfferDetail.name
  accepts_nested_attributes_for :best_offer_detail

  # An array of {EbayListing::NameValueListContainer}s describing the listing's
  # items specifics.
  # Generally all the item specifics will be in the *first* element of the array,
  # however eBay's API specification allows for many name-value lists.
  # @return [Array [EbayListing::NameValueListContainer]]
  embeds_many :item_specifics,
              as: :name_value_list_containable,
              class_name: EbayListing::NameValueListContainer.name
  accepts_nested_attributes_for :item_specifics

  embeds_one :listing_detail, class_name: EbayListing::ListingDetail.name
  accepts_nested_attributes_for :listing_detail
  validates :listing_detail, presence: true

  embeds_one :picture_detail, class_name: EbayListing::PictureDetail.name
  accepts_nested_attributes_for :picture_detail

  embeds_one :revise_state, class_name: EbayListing::ReviseState.name
  accepts_nested_attributes_for :revise_state

  embeds_one :shipping_detail, class_name: EbayListing::ShippingDetail.name
  accepts_nested_attributes_for :shipping_detail

  embeds_one :storefront, class_name: EbayListing::Storefront.name
  accepts_nested_attributes_for :storefront

  # @note Use {#add_timestamp} method to create new timestamps!
  embeds_many :timestamps, class_name: EbayListing::Timestamp.name, order: :time.asc
  validates :timestamps, presence: true # Ensure array is not empty

  embeds_one :variation_detail, class_name: EbayListing::VariationDetail.name, cascade_callbacks: true
  accepts_nested_attributes_for :variation_detail

  # @return [String] 3 character currency ISO code.
  field :currency, type: String, default: 'GBP'

  # @return [Fixnum] The maximum number of business days the seller commits to for preparing an item to be shipped after receiving a cleared payment.
  field :dispatch_time_max, type: Fixnum, default: 3

  # Determine if GetItFast shipping rules apply to this ebay_listing.
  # @return [Boolean] +true+ if GetItFast is supported
  # @note Not supported for UK Store Inventory format items.
  field :get_it_fast, type: Boolean, default: false

  # @return [Boolean] +true+ if this ebay_listing is hidden from search.
  field :hide_from_search, as: :hide_from_search?, type: Boolean, default: false

  # The number of page views.
  field :hit_count, type: Fixnum, default: 0

  # Set the hit_count value.
  # Prevent hit_count from being reset to 0, which can happen if a listing is cancelled.
  # @param [Fixnum] hits the number of page views.
  #
  def hit_count=(hits)
    hits = hits.to_i
    return self[:hit_count] if hits < self[:hit_count]
    self[:hit_count] = (hits >= 0 ? hits : 0)
  end

  # @return [Fixnum] the eBay item ID.
  field :item_id, type: Fixnum
  attr_readonly :item_id
  validates :item_id, presence: true, uniqueness: true
  index({item_id: 1}, { unique: true, name: 'item_id_index' })

  # @return [Fixnum] the ebay_listing duration in days where a value greater than 30 represents GTC.
  field :listing_duration, type: Fixnum
  validates :listing_duration, numericality: {only_integer: true, greater_than: 0}

  # The type of listing, which can be 'Chinese' or 'FixedPrice'.
  #
  # This field is NOT returned be GetSellerList calls!
  #
  # @return [String] The type of listing, 'Chinese' or 'FixedPrice'
  field :listing_type, type: String
  #validates :listing_type, presence: true

  # @return [Fixnum] the primary category ID.
  field :primary_category_id, type: Fixnum
  validates :primary_category_id, presence: true

  # The reason {#hide_from_search} may be +true+. Can be one of:
  # * DuplicateListing
  # * OutOfStock
  # @return [String] message describing why ebay_listing is hidden from search results.
  field :reason_hide_from_search, type: String

  # The eBay ID of the item from which this was re-listed.
  # @return [Fixnum] the parent ebay_listing eBay ID, or +nil+ if this is a fresh ebay_listing.
  field :relist_parent_id, type: Fixnum

  # @return [Money] the reserve price of +nil+ if none set.
  field :reserve_price, type: Money

  # @return [Fixnum] secondary category ID or nil.
  field :secondary_category_id, type: Fixnum

  field :sku, type: String
  validates :sku, presence: true
  index({sku: 1})

  # @return [String] The name of the site on which the item is listed.
  # @see http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/GetItem.html#Response.Item.Site
  # @note The ebay_listing site affects the business logic and validation rules that are applied to the request.
  field :site, type: String
  validates :site, presence: true

  # @return [String] an optional sub-title.
  field :sub_title, type: String

  # @return [String] the ebay_listing title.
  field :title, type: String
  validates :title, presence: true

  # @return [Boolean] +true+ if this is a top-rated ebay_listing.
  field :top_rated_listing, type: Boolean, default: false

  # Use UUID to ensure that you only list a particular item once.
  # If you add an item and do not get a response, resend the request
  # with the same UUID. If the item was successfully listed the first time,
  # you will receive an error message for trying to use a UUID that you
  # have already used.
  # @return [String] the UUID value set when ebay_listing/revising the item.
  field :uuid, type: String

  # The number of people watching this ebay_listing.
  field :watch_count, type: Fixnum, default: 0

  # Add an API call name {EbayListing::Timestamp} to this listing.
  # @param [Time] time the response time returned by the API request.
  # @param [String] call_name the name of the API call, such as +GetSellerList+.
  # @return [Boolean] +true+ if new timestamp successfully added.
  def add_timestamp(time, call_name)
    timestamps.each { |ts| return false if ts.time == time && ts.call_name == call_name }
    timestamp = EbayListing::Timestamp.new(time: time, call_name: call_name)
    return false unless timestamp.valid?
    # Delete any older timestamps from the same call_name
    timestamps.delete_if { |ts| ts.call_name == call_name }
    timestamps << timestamp
    true
  end

  # Get the +Time+ when this document was last updated via any API call.
  # @param [String] call_name optionally provide the name of the API call.
  # @return [Time] last updated time.
  def last_updated(call_name = nil)
    return nil if timestamps.empty?
    return timestamps.last.time if call_name.blank?
    timestamps.each { |ts| return ts.time if ts.call_name == call_name }
    nil
  end

  # Set the ebay_listing duration as a number of days.
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

  # Determine if this is a GTC ebay_listing.
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
    on_sale?(Time.now.utc)
  end

  def on_sale?(time)
    selling_state.on_sale?(time)
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
    item_specifics.first.names.each { |name| name_length_max = [name_length_max, name.length].max }
    item_specifics.first.each do |name, value|
      s << "#{name.rjust(name_length_max + 10)}  ->  #{value}\n"
    end

    s
  end

  # Migrate all EbayListing::Hit objects into EbayListingDailyHitCount objects.
  # To perform the migration call the following command from the rails console.
  #
  #   $ EbayListing.__migrate_hits_to_daily_hit_counts__
  #
  # @note {#update_daily_hit_count} must NOT be private when running this!
  #
  # @deprecated
  #
  def self.__migrate_hits_to_daily_hit_counts__(migration_date_time = '2016-02-01')
    time = Time.now
    puts
    puts "Deleting #{EbayListingDailyHitCount.count} EbayListingDailyHitCount's"
    EbayListingDailyHitCount.delete_all
    puts "EbayListingDailyHitCount.count = #{EbayListingDailyHitCount.count}"
    puts
    total_number_of_hits = EbayListing::Hit.count
    puts "Migrating #{total_number_of_hits} EbayListing::Hit to the new EbayListingDailyHitCount format"
    puts
    counter = 0
    EbayListing.includes(:hits, :seller).each do |listing|
      listing.hits.each do |hit|
        if hit.time < Time.parse(migration_date_time)
          print "  #{counter} of #{total_number_of_hits}  - eBay item:  #{listing.item_id}  #{hit.time}\r"
          listing.update_daily_hit_count(hit.time, hit.count)
          counter += 1
        end
      end
      puts; puts
    end
    puts
    duration = Time.now - time
    puts "Migration took #{(duration / 60).to_i} minutes"
  end

  #---------------------------------------------------------------------------
  #private

  def update_daily_hit_count(time = self.last_updated, hit_count_value = self.hit_count)
    if hit_count_value
      daily_hit_count = self.ebay_listing_daily_hit_counts.where(date: time.to_date).order_by(:date.asc).last
      previous = self.ebay_listing_daily_hit_counts.where(date: {'$lt': time.to_date}).order_by(:date.asc).last
      if daily_hit_count.nil?
        opening_balance = previous.nil? ? hit_count_value : previous.closing_balance
        daily_hit_count = EbayListingDailyHitCount.new(
            ebay_listing:     self,
            date:             time.to_date,
            opening_balance:  opening_balance,
            seller:           self.seller,
            item_id:          self.item_id,
            sku:              self.sku)
      end
      hit_count_value = previous.closing_balance if previous && previous.closing_balance > hit_count_value
      daily_hit_count.set_time_hit_count(hit_count_value, time)
      daily_hit_count.save!
    end
    true
  end


  # Add a new {EbayListing::Hit} to {hits} if the value of hit_count
  # has changed since last saved.
  # @deprecated
  #
  def update_hit_count_history
    last = hits.empty? ? 0 : hits.last.count
    if hit_count && hit_count > last
      hits << EbayListing::Hit.new(time: last_updated, count: hit_count)
    end
  end
  true
end
