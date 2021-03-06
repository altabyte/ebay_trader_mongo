class EbayListing::VariationDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :ebay_listing

  embeds_many :variations, class_name: EbayListing::Variation.name, cascade_callbacks: true
  accepts_nested_attributes_for :variations

  embeds_one :variation_picture, store_as: 'pictures', class_name: EbayListing::VariationPicture.name
  accepts_nested_attributes_for :variation_picture

  embeds_many :variation_specifics_sets,
              as: :name_value_list_containable,
              class_name: EbayListing::NameValueListContainer.name
  accepts_nested_attributes_for :variation_specifics_sets

end