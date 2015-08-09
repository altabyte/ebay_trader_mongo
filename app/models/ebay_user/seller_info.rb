class EbayUser::SellerInfo
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :ebay_user

  field :payment_method, type: String
  field :seller_business_type, type: String
  field :store_owner, type: Boolean, default: false
  field :store_site, type: String
  field :store_url, type: String
end