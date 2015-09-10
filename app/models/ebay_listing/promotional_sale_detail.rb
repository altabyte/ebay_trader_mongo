class EbayListing::PromotionalSaleDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  # @return [EbayListing] the ebay_listing to which these details belong.
  embedded_in :selling_state

  before_validation :capture_sale_price

  field :end_time, type: Time
  field :start_time, type: Time
  field :original_price, type: Money
  field :sale_price, type: Money

  validates :end_time, presence: true
  validates :start_time, presence: true
  validates :original_price, presence: true
  validates :sale_price, presence: true

  # Calculate the % discount if this ebay_listing is on sale.
  # @return [Fixnum] the percentage discount applied.
  def percentage_discount
    ((1 - (sale_price / original_price)) * 100).round.to_i
  end

  # @return [Boolean] +true+ if promotion applies now.
  def on_sale_now?
    Time.now.utc >= start_time && Time.now.utc <= end_time
  end

  #---------------------------------------------------------------------------
  private

  def capture_sale_price
    self.sale_price = selling_state.current_price if sale_price.nil?
  end
end