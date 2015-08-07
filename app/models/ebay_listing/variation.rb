class EbayListing::Variation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  include EbayListingItem # Functionality shared with EbayListing, located in concerns.

  embedded_in :variation_detail, class_name: EbayListing::VariationDetail.name

  embeds_many :variation_specifics,
             as: :name_value_list_containable,
             class_name: EbayListing::NameValueListContainer.name
  accepts_nested_attributes_for :variation_specifics
end