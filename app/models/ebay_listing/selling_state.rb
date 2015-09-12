class EbayListing::SellingState
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  # @return [EbayListing] the ebay_listing to which these details belong.
  embedded_in :ebay_listing

  embeds_many :promotional_sales, class_name: EbayListing::PromotionalSaleDetail.name, order: :end_time.asc, cascade_callbacks: true

  before_validation :capture_promotional_sale_event

  field :admin_ended, type: Boolean, default: false
  field :bid_count, type: Fixnum, default: 0
  field :current_price, type: Money
  field :lead_count, type: Fixnum, default: 0
  field :listing_state, type: String
  field :quantity_sold, type: Fixnum, default: 0
  field :quantity_sold_by_pickup_in_store, type: Fixnum, default: 0

  def has_promotion?
    !promotional_sales.last.nil?
  end

  def on_sale_now?
    on_sale?(Time.now.utc)
  end

  def on_sale?(time)
    promotional_sales.each { |sale| return true if sale.on_sale?(time) }
    false
  end

  #---------------------------------------------------------------------------
  private

  def capture_promotional_sale_event
    if self.respond_to? :promotional_sale_detail
      details = promotional_sale_detail
      details[:original_price] = Money.demongoize(details[:original_price]) if details[:original_price].is_a?(Hash)
      sale = EbayListing::PromotionalSaleDetail.new(details)
      sale.sale_price = current_price
      unset(:promotional_sale_detail)
      promotional_sales << sale unless promotional_sales.include?(sale)
    end
  end
end