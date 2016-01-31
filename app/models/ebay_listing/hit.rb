# A class to record the +hit_count+ history of an EbayListing.
#
# Note that the Hit time accuracy is proportional to the polling
# frequency of API calls such as +GetItem+ and +GetSellerList+.
#
# This class has several purposes.
# * Identify busy listings.
# * Identify stagnant listings.
# * Determine approximate busy times of the day.
# * Analyze if promotional sales have any influence on page views.
#
class EbayListing::Hit
  include Mongoid::Document

  store_in collection: 'ebay_listing_hits'

  before_validation :capture_listing_details

  belongs_to :ebay_listing

  field :time,    type: Time
  field :count,   type: Fixnum, default: 0
  field :sku,     type: String
  field :item_id, type: Fixnum
  field :on_sale, type: Boolean

  validates :time,  presence: true
  validates :count, presence: true

  index({item_id: 1})
  index({time: 1})

  #---------------------------------------------------------------------------
  private

  def capture_listing_details
    self.sku     = ebay_listing.sku          if self.sku.nil?
    self.item_id = ebay_listing.item_id      if self.item_id.nil?
    self.on_sale = ebay_listing.on_sale_now? if self.on_sale.nil?
  end
end