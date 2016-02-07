class EbayListingDailyHitCount::Hour
  include Mongoid::Document

  embedded_in :ebay_listing_daily_hit_count

  before_validation :capture_on_sale_status

  validates :ebay_listing_daily_hit_count,  presence: true
  validates :hour,                          presence: true
  validates :hits,                          presence: true
  validates :on_sale,                       presence: true

  # @return [Fixnum] the hour 0 -> 23
  field :hour, type: Fixnum

  # @return [Fixnum] the difference between the {#balance} this hour and the previous hour.
  field :hits, type: Fixnum, default: 0

  # @return [Boolean] was the listing on sale at this particular point in time?
  field :on_sale, type: Boolean, default: false

  def hits=(hits)
    self[:hits] = (hits > 0 ? hits : 0)
  end

  # Get a Time object associated with this hour.
  # @return [Time] the time represented by this hour.
  def time
    ebay_listing_daily_hit_count.date.to_time + hour.hours
  end

  #---------------------------------------------------------------------------
  private

  def capture_on_sale_status
    self.on_sale = ebay_listing_daily_hit_count.ebay_listing.on_sale?(time)
    true
  end
end
