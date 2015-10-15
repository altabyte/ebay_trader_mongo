class EbayListingDailyHitCount
  include Mongoid::Document

  belongs_to :ebay_listing

  embeds_many :hours, class_name: EbayListingDailyHitCount::Hour.name, order: :hour.asc

  before_create     :create_hours
  before_validation :capture_ebay_listing_details

  field :date,                type: Date
  field :opening_balance,     type: Fixnum, default: 0
  field :total_hits,          type: Fixnum, default: 0
  field :sku,                 type: String
  field :item_id,             type: Fixnum

  validates :ebay_listing,    presence: true
  validates :date,            presence: true
  validates :opening_balance, presence: true
  validates :total_hits,      presence: true
  validates :sku,             presence: true
  validates :item_id,         presence: true

  def set_time_hit_count(count, time)
    count = 0 if count < 0
    return count if count == closing_balance
    raise ArgumentError.new 'Time and date are not on the same day!' unless time.to_date == date
    hour = self.hours.where(hour: time.hour).first
    hour.hits += count - closing_balance
    self.total_hits = closing_balance - opening_balance
  end

  def closing_balance
    hours.inject(opening_balance) { |sum, hour| sum + hour.hits }
  end

  def hour_balance(hour_number)
    hour_number =  0 if hour_number <  0
    hour_number = 23 if hour_number > 23
    sum = opening_balance
    hours.each { |h| sum += h.hits if h.hour <= hour_number }
    sum
  end

  #---------------------------------------------------------------------------
  private

  def capture_ebay_listing_details
    self.sku     = ebay_listing.sku     if self.sku.nil?
    self.item_id = ebay_listing.item_id if self.item_id.nil?
  end

  def create_hours
    (0...24).each do |hour|
      hours << EbayListingDailyHitCount::Hour.new(hour: hour)
    end
  end
end
