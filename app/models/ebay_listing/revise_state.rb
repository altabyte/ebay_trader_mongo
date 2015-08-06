class EbayListing::ReviseState
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  # @return [EbayListing] the ebay_listing to which these details belong.
  embedded_in :ebay_listing

  field :buy_it_now_added,    type: Boolean, default: false
  field :buy_it_now_lowered,  type: Boolean, default: false
  field :item_revised,        type: Boolean, default: false
  field :reserve_lowered,     type: Boolean, default: false
  field :reserve_removed,     type: Boolean, default: false
end