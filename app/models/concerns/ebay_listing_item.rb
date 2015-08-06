module EbayListingItem
  extend ActiveSupport::Concern

  included do
    embeds_one :selling_state, class_name: 'Listing::SellingState' #, store_as: :selling_status
    accepts_nested_attributes_for :selling_state
    validates :selling_state, presence: true


    # @return [Fixnum] the number of items currently available.
    field :quantity_available, type: Fixnum, default: 0

    # @return [Fixnum] the number of items originally listed.
    field :quantity_listed, type: Fixnum, default: 0
    validates :quantity_listed, numericality: { only_integer: true, greater_than: 0 }

    # @return [String] the SKU, also known as the custom label in the UK.
    field :sku, type: String
    index({ sku: 1 }, { name: 'sku_index' })
    validates :sku, presence: true

    # The start price of this listing, which is actually its current price.
    # If the item is currently on sale then +sale_price+ will show the discounted price.
    # @return [Money] the start price.
    field :start_price, type: Money
    validates :start_price, presence: true
  end
end