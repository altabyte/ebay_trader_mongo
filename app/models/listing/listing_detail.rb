class Listing::ListingDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  # @return [Listing] the listing to which these details belong.
  embedded_in :listing

  # The new item ID for a re-listed item. When an item is re-listed, the item ID for the new item
  # is added to the old listing, so buyers can navigate to the new listing.
  # This value only appears when the old listing is retrieved.
  # The RelistedItemID of the original item should reflect the last relist.
  # @return [Fixnum] the eBay item ID of the new listing based upon this one, or +nil+ if not relisted.
  field :relisted_item_id, type: Fixnum

  # @return [Time] when this listing first became active on eBay.
  field :start_time, type: Time
  validates :start_time, presence: true

  # @return [Time] when this listing will end on eBay.
  field :end_time, type: Time
  validates :end_time, presence: true

  # This field is only returned if the item was ended early (before listing duration expired) by the seller.
  # Can be one of:
  # * Incorrect
  # * LostOrBroken
  # * NotAvailable
  # * OtherListingError
  # * SellToHighBidder
  # * Sold
  # @return [String] the seller's reason for ending this listing early.
  field :ending_reason, type: String

  # @return [Boolean] +true+ if a reserve price has been set.
  field :has_reserve_price, as: :has_reserve_price?, type: Boolean, default: false

  # @return [Money] the best offer auto accept price, or +nil+ if none set.
  field :best_offer_auto_accept_price, type: Money

  # @return [Money] the minimum acceptable best offer price, or +nil+ if none set.
  field :minimum_best_offer_price, type: Money

  # @return [String] the URL to view this listing on eBay.
  field :view_item_url, type: String

  # @return [String] the URL to view this listing on eBay.
  field :view_item_url_for_natural_search, type: String

  # @return [Boolean] true if this listing has unanswered questions.
  field :has_unanswered_questions, as: :has_unanswered_questions?, type: Boolean, default: false

  # @return [Boolean] true if this listing has public messages.
  field :has_public_messages, as: :has_public_messages?, type: Boolean, default: false

  # Get the total number of days this listing has been active.
  # @return [Fixnum] this number of days since first listed.
  #
  def days_active
    ((Time.now - start_time) / (24 * 60 * 60)).ceil.to_i
  end
end