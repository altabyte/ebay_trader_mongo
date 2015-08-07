class EbayListing::VariationSpecificPictureSet
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :variation_picture

  field :variation_specific_value, type: String
  validates :variation_specific_value, presence: true

  field :picture_url, type: Array, default: []
end



class EbayListing::VariationPicture
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :variation_detail

  embeds_many :variation_specific_picture_sets, class_name: EbayListing::VariationSpecificPictureSet.name

  field :variation_specific_name, type: String
  validates :variation_specific_name, presence: true

end

