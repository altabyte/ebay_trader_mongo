module EbayListingItem
  extend ActiveSupport::Concern

  included do

    before_validation :set_quantity_available

    embeds_one :selling_state, class_name: EbayListing::SellingState.name #, store_as: :selling_status
    accepts_nested_attributes_for :selling_state
    validates :selling_state, presence: true


    # @return [Fixnum] the number of items currently available.
    field :quantity_available, type: Fixnum, default: 0

    # @return [Fixnum] the number of items originally listed.
    field :quantity_listed, type: Fixnum, default: 0
    #validates :quantity_listed, numericality: { only_integer: true, greater_than: 0 }

    # @return [String] the SKU, also known as the custom label in the UK.
    field :sku, type: String
    index({ sku: 1 }, { name: 'sku_index' })
    validates :sku, presence: true

    # The start price of this ebay_listing, which is actually its current price.
    # If the item is currently on sale then +sale_price+ will show the discounted price.
    #
    # GetMyeBaySelling does not return Item.StartPrice for fixed price items--it returns
    # +Item.SellingStatus.CurrentPrice+.
    #
    # @return [Money] the start price.
    field :start_price, type: Money

    #---------------------------------------------------------------------------
    private

    def set_quantity_available
      self.quantity_available = self.quantity_listed - selling_state.quantity_sold
    end

  end
end