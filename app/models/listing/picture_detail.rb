class Listing::PictureDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  # @return [Listing] the listing to which these details belong.
  embedded_in :listing

  # Number of days that the Featured Gallery type applies to a listing.
  # Applicable values include:
  # * 'Days_7'
  # * 'LifeTime'
  # @return [String] gallery duration token.
  field :gallery_duration, type: String

  # Indicates if the gallery image upload failed and gives a reason for the failure,
  # such as 'InvalidUrl' or 'ServerDown'.
  # Returns +nil+ if the gallery image is uploaded successfully.
  field :gallery_state, type: String

  field :gallery_type, type: String, default: 'Gallery'

  field :gallery_url, type: String

  field :photo_display, type: String

  field :picture_url, type: Array, default: []

  def count
    picture_url.count
  end
end