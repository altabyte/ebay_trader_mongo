class EbayListing::BestOfferDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :ebay_listing

  field :best_offer_enabled, as: :best_offer_enabled?, type: Boolean, default: false
  field :best_offer_count, type: Fixnum, default: 0
  field :new_best_offer, as: :new_best_offer?, type: Boolean, default: false
end