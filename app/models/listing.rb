class Listing
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps # Define created_at and updated_at fields

  store_in collection: 'ebay_listings'

  embeds_one :listing_detail, class_name: 'Listing::ListingDetail'
  validates :listing_detail, presence: true

  # @return [Fixnum] the eBay item ID.
  field :item_id, type: Fixnum
  attr_readonly :item_id
  validates :item_id, presence: true, uniqueness: true
  index({ item_id: 1 }, { unique: true, name: 'item_id_index' })

  # @return [String] the SKU, also known as the custom label in the UK.
  field :sku, type: String
  index({ sku: 1 }, { name: 'sku_index' })
  validates :sku, presence: true

  # @return [String] the listing title.
  field :title, type: String
  validates :title, presence: true

  # @return [String] 3 character currency ISO code.
  field :currency, type: String, default: 'GBP'

  # @return [Money] the start price.
  field :start_price, type: Money
end
