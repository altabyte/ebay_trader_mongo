class Listing::Storefront
  include Mongoid::Document

  # @return [Listing] the listing to which these details belong.
  embedded_in :listing

  field :store_category_id,  type: Fixnum
  field :store_category2_id, type: Fixnum
  field :store_url,          type: String
end