class EbayListing::SellingState
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  # @return [EbayListing] the ebay_listing to which these details belong.
  embedded_in :ebay_listing

  # @return [Listing::PromotionalSaleDetail] an optional PromotionalSaleDetail.
  embeds_one :promotional_sale_detail, class_name: 'EbayListing::PromotionalSaleDetail'
  accepts_nested_attributes_for :promotional_sale_detail

  field :admin_ended, type: Boolean, default: false
  field :bid_count, type: Fixnum, default: 0
  field :current_price, type: Money
  validates :current_price, presence: true
  field :lead_count, type: Fixnum, default: 0
  field :listing_state, type: String
  validates :listing_state, presence: true
  field :quantity_sold, type: Fixnum, default: 0
  field :quantity_sold_by_pickup_in_store, type: Fixnum, default: 0

  def has_promotion?
    !promotional_sale_detail.nil?
  end

  def on_sale_now?
    has_promotion? && promotional_sale_detail.on_sale_now?
  end
end