class EbayListing::Storefront
  include Mongoid::Document

  # @return [EbayListing] the ebay_listing to which these details belong.
  embedded_in :ebay_listing

  field :store_category_id,  type: Fixnum
  field :store_category2_id, type: Fixnum
  field :store_url,          type: String
end