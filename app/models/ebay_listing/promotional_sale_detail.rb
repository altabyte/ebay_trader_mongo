class EbayListing::PromotionalSaleDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :selling_state, class_name: EbayListing::SellingState.name

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
    on_sale?(Time.now.utc)
  end

  def on_sale?(time)
    return false unless time && time.is_a?(Time)
    time > start_time && time < end_time
  end

  # Determine if the given PromotionalSaleDetail has the same values as this instance.
  # @return [Boolean] +true+ if all values match.
  def == (sale)
    return false if sale.nil? || !sale.is_a?(self.class)
    (sale.end_time == self.end_time && sale.start_time == self.start_time && sale.original_price == self.original_price)
  end

  #---------------------------------------------------------------------------
  private

  def capture_sale_price
    self.sale_price = selling_state.current_price if sale_price.nil?
  end
end