class Listing::ListingDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  # @return [Listing] the listing to which these details belong.
  embedded_in :listing

  # @return [Time] when this listing first became active on eBay.
  field :start_time, type: Time
  validates :start_time, presence: true

  # @return [Time] when this listing will end on eBay.
  field :end_time, type: Time
  validates :end_time, presence: true

  # @return [String] the URL to view this listing on eBay.
  field :view_item_url, type: String

  # @return [Boolean] true if this listing has unanswered questions.
  field :has_unanswered_questions, type: Boolean, default: false

  # @return [Boolean] true if this listing has public messages.
  field :has_public_messages, type: Boolean, default: false
end