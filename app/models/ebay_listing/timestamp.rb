class EbayListing::Timestamp
  include Mongoid::Document

  embedded_in :ebay_listing

  field :call_name, type: String
  field :time, type: Time

  validates :call_name, presence: true, inclusion: { in: %w(GetItem GetSellerEvent GetSellerList) }
  validates :time, presence: true

  def ==(another_timestamp)
    return false unless another_timestamp.is_a? EbayListing::Timestamp
    (time == another_timestamp.time && call_name == another_timestamp.call_name)
  end
end
