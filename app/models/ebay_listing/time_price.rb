# TimePrice is used to keep track of the price of a listing over time.
# This may be useful to see how sales or page views [Hits] vary with
# changes in price.
#
# Price changes can be manual, or the result of EbayListing::PromotionalSaleDetail.
#
class EbayListing::TimePrice
  include  Mongoid::Document

  embedded_in :selling_state, class_name: EbayListing::SellingState.name

  field :time, type: Time
  field :price, type: Money

  validates :time, presence: true
  validates :price, presence: true
end